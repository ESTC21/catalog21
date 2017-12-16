# encoding: utf-8

class SearchController < ApplicationController

  before_action :map_field_for_autocomplete, only: [:autocomplete]
  before_action :add_default_fq, only: [:index]

	# GET /searches
	# GET /searches.xml
	def index
		query_params = QueryFormat.catalog_format()
		puts "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
		puts params
		puts "YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY111111"
		# puts query_params
		puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
		
		#puts "adding instanceof exclusion to search parameters"
		#params["-instanceof"] = "http*"
		
		begin
			QueryFormat.transform_raw_parameters(params)
			puts "Past call to transform_raw_parameters"
			puts params

			# NOTES: When a search is fuzzy, the query string is not analyzed by solr.
			# This means (among other things) no stemming is done. Since
			# stemming happens at index-time, this can often result in no matches being found
			# for a fuzzy search. Example: periodical gets stemmed and indexed as period.
			# During a normal search, the query periorical also gets stemmed and matches
			# the index. If  the search is periodical~2, the query is NOT stemmed. periodical
			# will not match anything in the index (period) - even with the ~2, because period
			# is more than edit distance of 2 from periodical
			extra_query = ""
			fuzzy = params[:fuz_q]
			if params.has_key?(:fuz_q) && fuzzy != "+0"  # SKIP THIS FOR FUZZY 0: Exact match!
  			  original_q = params[:q]
     			orig_prefix = original_q[0]
     			orig_term = original_q[1..original_q.length]
     			stemmed_term = Stemmer::stem_word(orig_term)
          		stemmed_term.force_encoding("UTF-8")
     			params[:q] = "#{orig_prefix}#{stemmed_term}"
     			extra_query = "content:#{orig_term}^80"
     	   end

         if params.has_key?(:fuz_t)
            original_t = params[:t]
            orig_prefix = original_t[0]
            orig_term = original_t[1..original_t.length]
            stemmed_term = Stemmer::stem_word(orig_term)
            stemmed_term.force_encoding("UTF-8")
            params[:t] = "#{orig_prefix}#{stemmed_term}"
            @extra_fq += "title:#{orig_term}^80"
         end

			puts "Starting QueryFormat.create_solr_query"
			query = QueryFormat.create_solr_query(query_params, params, request.remote_ip)
			puts "Finished QueryFormat.create_solr_query"

			if !extra_query.blank?
			  q=query['q']
			  query['q'] = "#{extra_query} #{q}"
			end

      if !@extra_fq.blank?
        fq=query['fq']
        query['fq'] = "#{@extra_fq} #{fq}"
      end

			is_test = Rails.env == 'test' ? :test : :live
			is_test = :shards if params[:test_index]

			puts "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU"
			#puts query
			#ecerything looks good to this point

			solr = Solr.factory_create(is_test)
			@results = solr.search(query)

			respond_to do |format|
				format.html # index.html.erb
				format.json { render json: { results: @results } }
				format.xml
			end
		rescue ArgumentError => e
			render_error(e.to_s)
		rescue SolrException => e
			render_error(e.to_s, e.status())
		rescue Exception => e
			ExceptionNotifier.notify_exception(e, :env => request.env)
			render_error("Something unexpected went wrong.", :internal_server_error)
		end
	end

	# GET /searches/totals
	# GET /searches/totals.xml
	def totals
		is_test = Rails.env == 'test' ? :test : :live
		@totals = Solr.get_totals(is_test)
#		results = [ { :name => 'NINES', :total_docs => 400, :total_archives => 12}, { :name => '18thConnect', :total_docs => 800, :total_archives => 24 } ]

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @totals }
			format.xml  # index.xml.builder
		end
	end

	# GET /searches/autocomplete
	# GET /searches/autocomplete.xml
	def autocomplete
		query_params = QueryFormat.autocomplete_format()
		begin
			QueryFormat.transform_raw_parameters(params)
			query = QueryFormat.create_solr_query(query_params, params, request.remote_ip)
			query['field'] = "content_auto" if query['field'].blank?
			is_test = Rails.env == 'test' ? :test : :live
			is_test = :shards if params[:test_index]
			solr = Solr.factory_create(is_test)
			max = query['max'].to_i
			query.delete('max')
			words = solr.auto_complete(query)
			words.sort! { |a,b| b[:count] <=> a[:count] }
			words = words[0..(max-1)]
			@results = words.map { |word|
				{ :item => word[:name], :occurrences => word[:count] }
			}

			respond_to do |format|
				format.html # index.html.erb
				format.json { render json: { results: @results } }
				format.xml
			end
		rescue ArgumentError => e
			render_error(e.to_s)
		rescue SolrException => e
			render_error(e.to_s, e.status())
		rescue Exception => e
			ExceptionNotifier.notify_exception(e, :env => request.env)
			render_error("Something unexpected went wrong.", :internal_server_error)
		end
	end

	# GET /searches/names
	# GET /searches/names.xml
	def names
		query_params = QueryFormat.names_format()
		begin
			QueryFormat.transform_raw_parameters(params)
			query = QueryFormat.create_solr_query(query_params, params, request.remote_ip)
			is_test = Rails.env == 'test' ? :test : :live
			is_test = :shards if params[:test_index]
			solr = Solr.factory_create(is_test)
			@results = solr.names(query)

			respond_to do |format|
				format.html # index.html.erb
				format.json { render json: { results: @results }}
				format.xml
			end
		rescue ArgumentError => e
			render_error(e.to_s)
		rescue SolrException => e
			render_error(e.to_s, e.status())
		rescue Exception => e
			ExceptionNotifier.notify_exception(e, :env => request.env)
			render_error("Something unexpected went wrong.", :internal_server_error)
		end
  end

  # GET /search/languages.xml
  def languages
    # For the moment just return a list of all languages
    query_params = QueryFormat.languages_format()
    begin
      QueryFormat.transform_raw_parameters(params)
      query = QueryFormat.create_solr_query(query_params, params, request.remote_ip)

      is_test = Rails.env == 'test' ? :test : :live
      is_test = :shards if params[:test_index]
      solr = Solr.factory_create(is_test)

      @results = solr.languages(query)

      respond_to do |format|
        #format.html # languages.html.erb
		  format.json { render json: { results: @results }}
        format.xml # { render :xml => { :languages => @results } }
      end

      rescue ArgumentError => e
        render_error(e.to_s)
      rescue SolrException => e
        render_error(e.to_s, e.status())
      rescue Exception => e
		  ExceptionNotifier.notify_exception(e, :env => request.env)
        render_error("Something unexpected went wrong.", :internal_server_error)
    end
  end

	# GET /searches/details
	# GET /searches/details.xml
	def details
		query_params = QueryFormat.details_format()
		begin
			QueryFormat.transform_raw_parameters(params)
puts "11-------------------------------- #{query_params}"
puts "22-------------------------------- #{params}"
puts "request.remote_ip:: -------------------------------- #{request.remote_ip}"
			query = QueryFormat.create_solr_query(query_params, params, request.remote_ip)
			is_test = Rails.env == 'test' ? :test : :live
			is_test = :shards if params[:test_index]
			solr = Solr.factory_create(is_test)
			puts "33--------------------- #{query}"
			@document = solr.details(query)

			respond_to do |format|
				format.html # index.html.erb
				format.json { render json: { document: @document } }
				format.xml
			end
		rescue ArgumentError => e
			render_error(e.to_s)
		rescue SolrException => e
			render_error(e.to_s, e.status())
		rescue Exception => e
			ExceptionNotifier.notify_exception(e, :env => request.env)
			render_error("Something unexpected went wrong.", :internal_server_error)
		end
	end

	# GET /searches/modify
	# GET /searches/modify.xml
	def modify
		is_test = Rails.env == 'test' ? :test : :live
		is_test = :shards if params[:test_index]
		solr = Solr.factory_create(is_test)

		@response = solr.modify_object(params)

		if @response.empty?
			@response = "Solr object modified for uri: #{params[:uri]}"
		end

		respond_to do |format|			
			format.xml  # modify.xml.builder
		end
	end

  private
  def map_field_for_autocomplete
    fields = {
      'record_format' => 'format'
    }

    params[:field] = fields[params[:field]] || params[:field]
  end

  def add_default_fq
    @extra_fq = ""
    if params.has_key?(:fuz_q)
      @extra_fq += "-hasInstance:[* TO *]"
      @extra_fq += "-instanceof:[* TO *]"
    elsif params.has_key?(:r_own) || params.has_key?(:r_rps)
      @extra_fq += "instanceof:[* TO *]"
    else
      @extra_fq += "hasInstance:[* TO *]"
    end
  end

end
