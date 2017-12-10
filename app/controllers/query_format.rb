# encoding: UTF-8
##########################################################################
# Copyright 2011 Applied Research in Patacriticism and the University of Virginia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

class QueryFormat
	def self.transform_raw_parameters(params)
		# remove the parameters that are rails related and not set by the caller
		params.delete('controller')
		params.delete('action')
		params.delete('format')

		# add the closing quote to the needed fields
		if params['q']
			num_quotes = params['q'].count('"')
			if num_quotes % 2 != 0
				params['q'] = params['q'] + '"'
			end
		end
	end

	def self.term_info(typ)

		# This finds a utf8 word, plus allows the wildcards * and ? and the apostrophe
		w = /\p{Word}[\p{Word}'?*]*/
		verifications = {
		  :coverage => { :exp => /.*/u, :friendly => "Coverage" },
		  :publisher => { :exp => /.*/u, :friendly => "Imprint" },
		  :abbreviatedTitle => { :exp => /.*/u, :friendly => "Abbreviated Title" },
		  :variantTitle => { :exp => /.*/u, :friendly => "Variant Title" },
		  :earlierTitleProper => { :exp => /.*/u, :friendly => "Earlier Title" },
		  :titleProperOfSeries => { :exp => /.*/u, :friendly => "Series Title" },
      :description => { :exp => /.*/u, :friendly => "Note" },
      :subject => { :exp => /.*/u, :friendly => "Subject" },

		  :term => { :exp => /.*/u, :friendly => "A list of alphanumeric terms, starting with either + or - and possibly quoted if there is a space." },
		  :title => { :exp => /.*/u, :friendly => "A list of alphanumeric title, starting with either + or - and possibly quoted if there is a space." },
			#:term => { :exp => /^([+\-]("#{w}( #{w})*"|#{w}))+$/u, :friendly => "A list of alphanumeric terms, starting with either + or - and possibly quoted if there is a space." },
			:frag => { :exp => /^("#{w}( #{w})*"|#{w})$/u, :friendly => "A list of alphanumeric terms, possibly quoted if there is a space." },
      :year => { :exp => /^([+\-]\d{1,4}(\s+[tT][oO]\s+\d{1,4})?)$/, :friendly => "[+-] A 1 to 4 digit date." },
			:archive => { :exp => /^([+\-]\w[\w\- ]*)$/, :friendly => "[+-] One of the predefined archive abbreviations." },
			:genre => { :exp => /^([+\-]\w[ \w,]*)+$/, :friendly => "[+-] One or more of the predefined genres." },
			:genre2 => { :exp => /^(\w[ \w,]*)+(;(\w[ \w,]*)+)*$/, :friendly => "One or more of the predefined genres separated by semicolons." },
			:discipline2 => { :exp => /^(\w[ \w]*)+(;(\w[ \w]*)+)*$/, :friendly => "One or more of the predefined disciplines separated by semicolons." },
			:federation => { :exp => /^([+\-])federation:(\(?\w+( OR \w+)*\)?)$/, :friendly => "[+-] One or more of the predefined federations." },
			:other_facet => { :exp => /^([+\-](freeculture|fulltext|ocr|typewright))+$/, :friendly => "[+-] One of freeculture, fulltext, typewright, or ocr." },
			:sort => { :exp => /^(title|author|year) (asc|desc)$/, :friendly => "One of title, author, or year followed by one of asc or desc." },
			:starting_row => { :exp => /^\d+$/, :friendly => "The zero-based index of the results to start on." },
			:max => { :exp => /^\d+$/, :friendly => "The page size, or the maximum number of results to return at once." },
			:highlighting => { :exp => /^(on|off)$/, :friendly => "Whether to return highlighted text, if available. (Pass on or off.)" },
			:field => { :exp => /^(author|title|editor|publisher|content)$/, :friendly => "Which field to autocomplete. (One of author, title, editor, publisher, content.)" },
			:uri => { :exp => /^([A-Za-z0-9+.-]+):\/\/.+$/, :friendly => "The URI of the object to return."},
			:id => { :exp => /^[0-9]+$/, :friendly => "The unique integer ID of the object."},
			:commit => { :exp => /^(immediate|delayed)$/, :friendly => "Whether to commit the change now, or wait for the background task to commit. (immediate or delayed)"},
			:exhibit_type => { :exp => /^(partial|whole)$/, :friendly => "Whether the object is the entire work or just a page of it."},
			:string => { :exp => /^.+$/, :friendly => "Any string."},
			:string_optional => { :exp => /^.*$/, :friendly => "Any string."},
			:boolean => { :exp => /^(true|false)$/, :friendly => "true or false."},
			:section => { :exp => /^(community|classroom|peer-reviewed)$/, :friendly => "One of community, classroom, or peer-reviewed."},
			:visibility => { :exp => /^(all)$/, :friendly => "all or TBD."},
			:object_type => { :exp => /^(Group|Exhibit|Cluster|DiscussionThread)$/, :friendly => "One of Group, Exhibit, Cluster, or DiscussionThread."},
			:decimal => { :exp => /^\d+$/, :friendly => "An integer."},
			:decimal_array => { :exp => /^\d+(,\d+)*$/, :friendly => "An integer or array of integers separated by commas."},
			:local_sort => { :exp => /^(title|last_modified) (asc|desc)$/, :friendly => "One of title or last_modified followed by one of asc or desc." },
			:last_modified => { :exp => /^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ$/, :friendly => "A date/time string in the format: yyyy-mm-ddThh:mm:ssZ." },
      :fuz_value => { :exp => /^[+\-]?[012]?$/, :friendly => "Fuzzyness: 0 (exact match), 1 (varied spellings) or 2 (most varied spellings)"},
      :language => { :exp => /^([+\-][^+\-]+)+$/, :friendly => "[+-] Languages separated by ||" },
      :facet => { :exp => /^(\b(?:doc_type|archive|discipline|genre|free_culture|federation),*)+$/, :friendly => 'One or more of the predefined facets separated by commas (doc_type, archive, discipline, genre, free_culture, federation)'},
      :period_pivot => { :exp => /^(doc_type|archive|discipline|genre|free_culture|federation)$/, :friendly => 'One of the predefined pivots (doc_type, archive, discipline, genre, free_culture, or federation)'},
			:fq => {:exp => /.*/u, :friendly => "A filter query of form fq:XXXXXX" }
		}

		return verifications[typ]
	end

	def self.add_to_format(format)
		format.each { |key,val|
			typ = val[:param]

			description = QueryFormat.term_info(typ)
			format[key][:description] = description[:friendly]
			format[key][:exp] = description[:exp]
			if format[key][:default]
				format[key][:description] += " [default=#{format[key][:default]}]"
			else
				format[key][:description] += " [default=not present]"
			end
		}
		return format
	end

	def self.catalog_format()
		format = {
				# New RDF model fields
				'coverage' => { :name => 'Coverage', :param => :coverage, :default => nil, :transformation => get_proc(:transform_coverage) },
				'publisher' => { :name => 'Imprint', :param => :publisher, :default => nil, :transformation => get_proc(:transform_imprint) },
				'abbreviatedTitle' => { :name => 'Abbreviated Title', :param => :abbreviatedTitle, :default => nil,
																:transformation => get_proc(:transform_abbreviatedTitle) },
				'variantTitle' => { :name => 'Variant Title', :param => :variantTitle, :default => nil,
																:transformation => get_proc(:transform_variantTitle) },
				'earlierTitleProper' => { :name => 'Earlier Title', :param => :earlierTitleProper, :default => nil,
																:transformation => get_proc(:transform_earlierTitleProper) },
				'titleProperOfSeries' => { :name => 'Series Title', :param => :titleProperOfSeries, :default => nil,
																:transformation => get_proc(:transform_titleProperOfSeries) },
        'subject' => { :name => 'Subject', :param => :subject, :default => nil,
                                :transformation => get_proc(:transform_subject) },
				'q' => { :name => 'Query', :param => :term, :default => nil, :can_fuz => true, :transformation => get_proc(:transform_title) },
        'fuz_q' => { :name => 'Query Fuzz Value', :param => :fuz_value, :default => nil, :transformation => get_proc(:transform_nil) },
				't' => { :name => 'Title', :param => :title, :default => nil, :can_fuz => true, :transformation => get_proc(:transform_title_only) },
        'fuz_t' => { :name => 'Title Fuzz Value', :param => :fuz_value, :default => nil, :transformation => get_proc(:transform_nil) },
				'aut' => { :name => 'Author', :param => :term, :default => nil, :transformation => get_proc(:transform_author) },
				'ed' => { :name => 'Editor', :param => :term, :default => nil, :transformation => get_proc(:transform_editor) },
				'pub' => { :name => 'Publisher', :param => :term, :default => nil, :transformation => get_proc(:transform_publisher) },
				'y' => { :name => 'Year', :param => :year, :default => nil, :transformation => get_proc(:transform_year) },
				'a' => { :name => 'Archive', :param => :archive, :default => nil, :transformation => get_proc(:transform_archive) },
				'g' => { :name => 'Genre', :param => :genre, :default => nil, :transformation => get_proc(:transform_genre) },
				'f' => { :name => 'Federation', :param => :federation, :default => nil, :transformation => get_proc(:transform_federation) },
        'facet' => { :name => 'Facet', :param => :facet, :default => nil, :transformation => get_proc(:transform_facet) },
				'o' => { :name => 'Other Facet', :param => :other_facet, :default => nil, :transformation => get_proc(:transform_other) },
				'sort' => { :name => 'Sort', :param => :sort, :default => nil, :transformation => get_proc(:transform_sort) },
				'start' => { :name => 'Starting Row', :param => :starting_row, :default => '0', :transformation => get_proc(:transform_field) },
				'max' => { :name => 'Maximum Results', :param => :max, :default => '30', :transformation => get_proc(:transform_max) },
				'hl' => { :name => 'Highlighting', :param => :highlighting, :default => 'off', :transformation => get_proc(:transform_highlight) },
				'test_index' => { :name => 'Use Testing Index', :param => :boolean, :default => nil, :transformation => get_proc(:transform_nil) },
        'r_own' => { :name => 'Owner', :param => :string, :default => nil, :transformation => get_proc(:transform_role_owner)},
        'r_art' => { :name => 'Artist', :param => :string, :default => nil, :transformation => get_proc(:transform_role_artist)},
        'r_rps' => { :name => 'Repository', :param => :string, :default => nil, :transformation => get_proc(:transform_role_repository)},
        'lang' => { :name => 'Language', :param => :language, :default => nil, :transformation => get_proc(:transform_language)},
        'doc_type' => { :name => 'Format', :param => :string, :default => nil, :transformation => get_proc(:transform_doc_type)},
        'discipline' => { :name => 'Discipline', :param => :string, :default => nil, :transformation => get_proc(:transform_discipline)},
        'role_TRL' => { :name => 'Translator', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_ARC' => { :name => 'Architect', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_BND' => { :name => 'Binder', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_BKD' => { :name => 'Book Designer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_BKP' => { :name => 'Book Producer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_BRD' => { :name => 'Broadcaster', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_CLL' => { :name => 'Calligrapher', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_CTG' => { :name => 'Cartographer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_COL' => { :name => 'Collector', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_CLR' => { :name => 'Colorist', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_CWT' => { :name => 'Commentator', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_COM' => { :name => 'Compiler', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_CMT' => { :name => 'Compositor', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_CNG' => { :name => 'Cinematographer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
	    	'role_CND' => { :name => 'Conductor', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
	    	'role_CRE' => { :name => 'Creator', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
	    	'role_DRT' => { :name => 'Director', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_DUB' => { :name => 'Dubious Author', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_FAC' => { :name => 'Facsimilist', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_FMO' => { :name => 'Former Owner', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_ILU' => { :name => 'Illuminator', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_ILL' => { :name => 'Illustrator', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_IVR' => { :name => 'Interviewer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_IVE' => { :name => 'Interviewee', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_LTG' => { :name => 'Lithographer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_OWN' => { :name => 'Owner', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_PRT' => { :name => 'Printer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_POP' => { :name => 'Printer of plates', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_PRF' => { :name => 'Performer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_PRM' => { :name => 'Printmaker', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_PRN' => { :name => 'Production Company', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_PRO' => { :name => 'Producer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_RPS' => { :name => 'Repository', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_RBR' => { :name => 'Rubricator', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_SCR' => { :name => 'Scribe', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_SCL' => { :name => 'Sculptor', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_TYD' => { :name => 'Type Designer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_TYG' => { :name => 'Typographer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_WDE' => { :name => 'Wood Engraver', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_WDC' => { :name => 'Wood Cutter', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'period_pivot' => { :name => 'Period Pivot', :param => :period_pivot, :default => nil, :transformation => get_proc(:transform_pivot) },
        'fq' => { :name => 'Query Filter', :param => :fq, :default => nil, :transformation => get_proc(:transform_fq) },
        'uri' => { :name => 'ID', :param => :uri, :default => nil, :transformation => get_proc(:transform_uri) }
		}
		return self.add_to_format(format)
	end

	def self.autocomplete_format()
		format = {
				'field' => { :name => 'Field', :param => :field, :default => 'content', :transformation => get_proc(:transform_field_ascii) },
				'frag' => { :name => 'Fragment to Match', :param => :frag, :default => nil, :transformation => get_proc(:transform_frag) },
				'max' => { :name => 'Maximum matches to return', :param => :max, :default => '15', :transformation => get_proc(:transform_max_matches) },

				'q' => { :name => 'Query', :param => :term, :default => nil, :transformation => get_proc(:transform_query) },
				't' => { :name => 'Title', :param => :title, :default => nil, :transformation => get_proc(:transform_title_only) },
				'aut' => { :name => 'Author', :param => :term, :default => nil, :transformation => get_proc(:transform_author) },
				'ed' => { :name => 'Editor', :param => :term, :default => nil, :transformation => get_proc(:transform_editor) },
				'pub' => { :name => 'Publisher', :param => :term, :default => nil, :transformation => get_proc(:transform_publisher) },
				'y' => { :name => 'Year', :param => :year, :default => nil, :transformation => get_proc(:transform_year) },
				'a' => { :name => 'Archive', :param => :archive, :default => nil, :transformation => get_proc(:transform_archive) },
				'g' => { :name => 'Genre', :param => :genre, :default => nil, :transformation => get_proc(:transform_genre) },
				'f' => { :name => 'Federation', :param => :federation, :default => nil, :transformation => get_proc(:transform_federation) },
				'o' => { :name => 'Other Facet', :param => :other_facet, :default => nil, :transformation => get_proc(:transform_other) },
				'test_index' => { :name => 'Use Testing Index', :param => :boolean, :default => nil, :transformation => get_proc(:transform_nil) },
        'r_own' => { :name => 'Owner', :param => :string, :default => nil, :transformation => get_proc(:transform_role_owner)},
        'r_art' => { :name => 'Artist', :param => :string, :default => nil, :transformation => get_proc(:transform_role_artist)},
        'lang' => { :name => 'Language', :param => :language, :default => nil, :transformation => get_proc(:transform_language)},
		    'doc_type' => { :name => 'Format', :param => :string, :default => nil, :transformation => get_proc(:transform_doc_type)},
		    'discipline' => { :name => 'Discipline', :param => :string, :default => nil, :transformation => get_proc(:transform_discipline)},
        'role_TRL' => { :name => 'Translator', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_ARC' => { :name => 'Architect', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_BND' => { :name => 'Binder', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_BKD' => { :name => 'Book Designer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_BKP' => { :name => 'Book Producer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_BRD' => { :name => 'Broadcaster', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_CLL' => { :name => 'Calligrapher', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_CTG' => { :name => 'Cartographer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_COL' => { :name => 'Collector', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_CLR' => { :name => 'Colorist', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_CWT' => { :name => 'Commentator', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_COM' => { :name => 'Compiler', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_CMT' => { :name => 'Compositor', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_CNG' => { :name => 'Cinematographer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_CND' => { :name => 'Conductor', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_DRT' => { :name => 'Director', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_CRE' => { :name => 'Creator', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_DUB' => { :name => 'Dubious Author', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_FAC' => { :name => 'Facsimilist', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_FMO' => { :name => 'Former Owner', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_ILU' => { :name => 'Illuminator', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_ILL' => { :name => 'Illustrator', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_IVR' => { :name => 'Interviewer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_IVE' => { :name => 'Interviewee', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_LTG' => { :name => 'Lithographer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_OWN' => { :name => 'Owner', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_PRF' => { :name => 'Performer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_PRT' => { :name => 'Printer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_POP' => { :name => 'Printer of plates', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_PRM' => { :name => 'Printmaker', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_PRN' => { :name => 'Production Company', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_PRO' => { :name => 'Producer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_RPS' => { :name => 'Repository', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_RBR' => { :name => 'Rubricator', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_SCR' => { :name => 'Scribe', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_SCL' => { :name => 'Sculptor', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_TYD' => { :name => 'Type Designer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_TYG' => { :name => 'Typographer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_WDE' => { :name => 'Wood Engraver', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_WDC' => { :name => 'Wood Cutter', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)}
		}
		return self.add_to_format(format)
	end

	def self.names_format()
		format = {
				'q' => { :name => 'Query', :param => :term, :default => nil, :transformation => get_proc(:transform_query) },
				'fuz_q' => { :name => 'Query Fuzz Value', :param => :fuz_value, :default => nil, :transformation => get_proc(:transform_nil) },
				't' => { :name => 'Title', :param => :term, :default => nil, :transformation => get_proc(:transform_title_only) },
				'aut' => { :name => 'Author', :param => :term, :default => nil, :transformation => get_proc(:transform_author) },
				'ed' => { :name => 'Editor', :param => :term, :default => nil, :transformation => get_proc(:transform_editor) },
				'pub' => { :name => 'Publisher', :param => :term, :default => nil, :transformation => get_proc(:transform_publisher) },
				'y' => { :name => 'Year', :param => :year, :default => nil, :transformation => get_proc(:transform_year) },
				'a' => { :name => 'Archive', :param => :archive, :default => nil, :transformation => get_proc(:transform_archive) },
				'g' => { :name => 'Genre', :param => :genre, :default => nil, :transformation => get_proc(:transform_genre) },
				'f' => { :name => 'Federation', :param => :federation, :default => nil, :transformation => get_proc(:transform_federation) },
				'o' => { :name => 'Other Facet', :param => :other_facet, :default => nil, :transformation => get_proc(:transform_other) },
				'test_index' => { :name => 'Use Testing Index', :param => :boolean, :default => nil, :transformation => get_proc(:transform_nil) },
        'r_own' => { :name => 'Owner', :param => :string, :default => nil, :transformation => get_proc(:transform_role_owner)},
        'r_art' => { :name => 'Artist', :param => :string, :default => nil, :transformation => get_proc(:transform_role_artist)},
        'lang' => { :name => 'Language', :param => :language, :default => nil, :transformation => get_proc(:transform_language)},
        'doc_type' => { :name => 'Format', :param => :string, :default => nil, :transformation => get_proc(:transform_doc_type)},
        'discipline' => { :name => 'Discipline', :param => :string, :default => nil, :transformation => get_proc(:transform_discipline)},
        'role_TRL' => { :name => 'Translator', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_ARC' => { :name => 'Architect', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_BND' => { :name => 'Binder', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_BKD' => { :name => 'Book Designer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_BKP' => { :name => 'Book Producer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_BRD' => { :name => 'Broadcaster', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_CLL' => { :name => 'Calligrapher', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_CTG' => { :name => 'Cartographer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_COL' => { :name => 'Collector', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_CLR' => { :name => 'Colorist', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_CWT' => { :name => 'Commentator', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_COM' => { :name => 'Compiler', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_CMT' => { :name => 'Compositor', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_CNG' => { :name => 'Cinematographer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_CND' => { :name => 'Conductor', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_DRT' => { :name => 'Director', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_CRE' => { :name => 'Creator', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_DUB' => { :name => 'Dubious Author', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_FAC' => { :name => 'Facsimilist', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_FMO' => { :name => 'Former Owner', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_ILU' => { :name => 'Illuminator', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_ILL' => { :name => 'Illustrator', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_IVR' => { :name => 'Interviewer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_IVE' => { :name => 'Interviewee', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_LTG' => { :name => 'Lithographer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_OWN' => { :name => 'Owner', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_PRT' => { :name => 'Printer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_POP' => { :name => 'Printer of plates', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_PRF' => { :name => 'Performer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_PRM' => { :name => 'Printmaker', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_PRN' => { :name => 'Production Company', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
		    'role_PRO' => { :name => 'Producer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_RPS' => { :name => 'Repository', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_RBR' => { :name => 'Rubricator', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_SCR' => { :name => 'Scribe', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_SCL' => { :name => 'Sculptor', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_TYD' => { :name => 'Type Designer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_TYG' => { :name => 'Typographer', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_WDE' => { :name => 'Wood Engraver', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)},
        'role_WDC' => { :name => 'Wood Cutter', :param => :string, :default => nil, :transformation => get_proc(:transform_role_generic)}
		}
		return self.add_to_format(format)
  end

  def self.languages_format()
    format = {
        'q' => { :name => 'Query', :param => :term, :default => nil, :transformation => get_proc(:transform_query) },
        't' => { :name => 'Title', :param => :title, :default => nil, :transformation => get_proc(:transform_title_only) },
        'aut' => { :name => 'Author', :param => :term, :default => nil, :transformation => get_proc(:transform_author) },
        'ed' => { :name => 'Editor', :param => :term, :default => nil, :transformation => get_proc(:transform_editor) },
        'pub' => { :name => 'Publisher', :param => :term, :default => nil, :transformation => get_proc(:transform_publisher) },
        'y' => { :name => 'Year', :param => :year, :default => nil, :transformation => get_proc(:transform_year) },
        'a' => { :name => 'Archive', :param => :archive, :default => nil, :transformation => get_proc(:transform_archive) },
        'g' => { :name => 'Genre', :param => :genre, :default => nil, :transformation => get_proc(:transform_genre) },
        'f' => { :name => 'Federation', :param => :federation, :default => nil, :transformation => get_proc(:transform_federation) },
        'o' => { :name => 'Other Facet', :param => :other_facet, :default => nil, :transformation => get_proc(:transform_other) },
        'test_index' => { :name => 'Use Testing Index', :param => :boolean, :default => nil, :transformation => get_proc(:transform_nil) },
    }
    return self.add_to_format(format)
  end

	def self.details_format()
		format = {
				'uri' => { :name => 'URI', :param => :uri, :default => nil, :transformation => get_proc(:transform_uri) },
				'test_index' => { :name => 'Use Testing Index', :param => :boolean, :default => nil, :transformation => get_proc(:transform_nil) }
		}
		return self.add_to_format(format)
	end

	def self.exhibit_format()
		format = {
			'id' => { :name => 'ID', :param => :id, :default => nil, :transformation => get_proc(:transform_id) },
			'commit' => { :name => 'Commit?', :param => :commit, :default => nil, :transformation => get_proc(:transform_nil) },
			'type' => { :name => 'Type', :param => :exhibit_type, :default => nil, :transformation => get_proc(:transform_nil) },
			'page' => { :name => 'Page number', :param => :id, :default => nil, :transformation => get_proc(:transform_nil) },
			'federation' => { :name => 'federation', :param => :string, :default => nil, :transformation => get_proc(:transform_field) },

			# Multivalued fields
			'alternative' => { :name => 'alternative', :param => :string, :default => nil, :transformation => get_proc(:transform_field), :can_be_array => true },
			#'date_label' => { :name => 'date_label', :param => :string, :default => nil, :transformation => get_proc(:transform_field), :can_be_array => true },
			'genre' => { :name => 'genre', :param => :genre2, :default => nil, :transformation => get_proc(:transform_field), :can_be_array => true },
			'discipline' => { :name => 'discipline', :param => :discipline2, :default => nil, :transformation => get_proc(:transform_field), :can_be_array => true },
			'role_AUT' => { :name => 'Author', :param => :string, :default => nil, :transformation => get_proc(:transform_field), :can_be_array => true },
			'role_PBL' => { :name => 'Publisher', :param => :string, :default => nil, :transformation => get_proc(:transform_field), :can_be_array => true },
			#'role_ART' => { :name => 'Artist', :param => :string, :default => nil, :transformation => get_proc(:transform_field), :can_be_array => true },
			#'role_EDT' => { :name => 'Editor', :param => :string, :default => nil, :transformation => get_proc(:transform_field), :can_be_array => true },
			#'role_TRL' => { :name => 'Translator', :param => :string, :default => nil, :transformation => get_proc(:transform_field), :can_be_array => true },
			#'role_EGR' => { :name => 'Engraver', :param => :string, :default => nil, :transformation => get_proc(:transform_field), :can_be_array => true },
			#'role_ETR' => { :name => 'Etcher', :param => :string, :default => nil, :transformation => get_proc(:transform_field), :can_be_array => true },
			#'role_CRE' => { :name => 'Creator', :param => :string, :default => nil, :transformation => get_proc(:transform_field), :can_be_array => true },
			'year' => { :name => 'year', :param => :string, :default => nil, :transformation => get_proc(:transform_field), :can_be_array => true },

			# single valued fields
			#'image' => { :name => 'image', :param => :string, :default => nil, :transformation => get_proc(:transform_field) },
			'archive' => { :name => 'archive', :param => :string, :default => nil, :transformation => get_proc(:transform_field) },
			'archive_name' => { :name => 'archive_name', :param => :string, :default => nil, :transformation => get_proc(:transform_field) },
			'archive_url' => { :name => 'archive_url', :param => :string, :default => nil, :transformation => get_proc(:transform_field) },
			'archive_thumbnail' => { :name => 'archive_thumbnail', :param => :string, :default => nil, :transformation => get_proc(:transform_field) },
			'source' => { :name => 'source', :param => :string, :default => nil, :transformation => get_proc(:transform_field) },
			'text' => { :name => 'text', :param => :string, :default => nil, :transformation => get_proc(:transform_field) },
			'text_url' => { :name => 'text_url', :param => :string, :default => nil, :transformation => get_proc(:transform_field) },
			'thumbnail' => { :name => 'thumbnail', :param => :string, :default => nil, :transformation => get_proc(:transform_field) },
			'title' => { :name => 'title', :param => :string, :default => nil, :transformation => get_proc(:transform_field) },
			'title_sort' => { :name => 'title_sort', :param => :string, :default => nil, :transformation => get_proc(:transform_field) },
			'author_sort' => { :name => 'author_sort', :param => :string, :default => nil, :transformation => get_proc(:transform_field) },
			'url' => { :name => 'url', :param => :string, :default => nil, :transformation => get_proc(:transform_field) }

			# boolean fields
			#'has_full_text' => { :name => 'has_full_text', :param => :boolean, :default => 'false', :transformation => get_proc(:transform_field) },
			#'is_ocr' => { :name => 'is_ocr', :param => :boolean, :default => 'false', :transformation => get_proc(:transform_field) },
			#'freeculture' => { :name => 'freeculture', :param => :boolean, :default => 'false', :transformation => get_proc(:transform_field) },
			#'typewright' => { :name => 'typewright', :param => :boolean, :default => 'false', :transformation => get_proc(:transform_field) }
		}
		return self.add_to_format(format)
	end

	def self.locals_format()
		format = {
				'q' => { :name => 'Query', :param => :term, :default => nil, :transformation => get_proc(:transform_query) },
				'sort' => { :name => 'Sort', :param => :local_sort, :default => nil, :transformation => get_proc(:transform_sort) },
				'start' => { :name => 'Starting Row', :param => :starting_row, :default => '0', :transformation => get_proc(:transform_field) },
				'max' => { :name => 'Maximum Results', :param => :max, :default => '30', :transformation => get_proc(:transform_max) },
				'section' => { :name => 'Section', :param => :section, :default => nil, :transformation => get_proc(:transform_section) },
				'member' => { :name => 'All Group IDs that the user is a member of', :param => :decimal_array, :default => nil, :transformation => get_proc(:transform_group_membership) },
				'admin' => { :name => 'All Group IDs that the user is an admin of', :param => :decimal_array, :default => nil, :transformation => get_proc(:transform_group_admin) },
				'object_type' => { :name => 'Object Type', :param => :object_type, :default => nil, :transformation => get_proc(:transform_object_type) },
				'group' => { :name => 'Group ID', :param => :decimal, :default => nil, :transformation => get_proc(:transform_group) },
				'federation' => { :name => 'Federation', :param => :string, :default => nil, :transformation => get_proc(:transform_nil) }
		}
		return self.add_to_format(format)
	end

	def self.add_locals_format()
		format = {
				'section' => { :name => 'Section', :param => :section, :default => nil, :transformation => get_proc(:transform_field) },
				'object_type' => { :name => 'Object Type', :param => :object_type, :default => nil, :transformation => get_proc(:transform_field) },
				'object_id' => { :name => 'Object ID', :param => :decimal, :default => nil, :transformation => get_proc(:transform_field) },
				'group_id' => { :name => 'Group ID', :param => :decimal, :default => nil, :transformation => get_proc(:transform_field) },
				'title' => { :name => 'title', :param => :string, :default => nil, :transformation => get_proc(:transform_field) },
				'text' => { :name => 'text', :param => :string_optional, :default => nil, :transformation => get_proc(:transform_field) },
				'last_modified' => { :name => 'Last Modified', :param => :last_modified, :default => nil, :transformation => get_proc(:transform_last_modified) },
				'visible_to_everyone' => { :name => 'Visible to Everyone', :param => :boolean, :default => nil, :transformation => get_proc(:transform_field) },
				'visible_to_group_member' => { :name => 'Visible to Member', :param => :decimal, :default => nil, :transformation => get_proc(:transform_field) },
				'visible_to_group_admin' => { :name => 'Visible to Admin', :param => :decimal, :default => nil, :transformation => get_proc(:transform_field) },
				'federation' => { :name => 'Federation', :param => :string, :default => nil, :transformation => get_proc(:transform_field) }
		}
		return self.add_to_format(format)
	end

	def self.get_proc( method_sym )
	  self.method( method_sym ).to_proc
	end

	def self.diacritical_query_data(field, val, fuz=nil)
		v = (val.include?('+uri') ? val : val.downcase())
		return "#{v}"
	end

	def self.transform_query(key, val, fuz=nil)
		puts "inside transform_query #{key} #{val} #{fuz}"
		return self.transform_fuz_query(key, val, fuz) unless fuz.blank?
		# To find diacriticals, the main search strips them off, then we include an optional boosted search with them
		return { 'q' => self.diacritical_query_data("content", val, fuz) }
	end

  def self.transform_fuz_query(key, val, fuz)
    v = val.downcase()
    return { 'q' => "#{insert_field_name('content', v, 20, nil)} #{insert_field_name('content', v, nil, fuz)}" }
  end

	#partitions a string based on regex.  matches are included in results
	#ex. 'a b  c'.partition(/ +/) returns ['a', ' ', 'b', '  ', 'c']
	#ex. ' b '.partition(/ +/) returns [' ', 'b', ' ']
	def self.partition(str, regex)
		results = []
		s = StringScanner.new(str)
		last_pos = 0
		ascii = str.dup.force_encoding("ASCII-8BIT")
		while(s.skip_until(regex))
			matched_size = s.matched_size
			pos = s.pos
			#add the non-delimiter string if it exists (it may not if the string starts with a delimiter)
			# HACK: StringScanner evidently returns bytes instead of strings, so we have to translate the utf8 string to ascii temporarily.
			results << ascii[last_pos ... pos - matched_size].force_encoding("UTF-8") if last_pos < pos - matched_size
			#add the delimiter
			results << ascii[pos - matched_size ... pos].force_encoding("UTF-8")
			#update the last_pos to the current pos
			last_pos = pos
		end
		#add the last non-delimiter string if one exists after the last delimiter.  It would not have
		#been added since s.skip_until would have returned nil
		results << ascii[last_pos ... ascii.length].force_encoding("UTF-8") if last_pos < str.length
		return results
	end

	def self.make_pairs(str, regex)
		# this is of the format ([+|-]match)+
		# we want to break it into its component parts
		results = self.partition(str, regex)
		pairs = []
		results.each { |result|
			if pairs.last && pairs.last.length == 1
				pairs.last.push(result)
			else
				pairs.push([result])
			end
		}
		pairs.last.push("") if pairs.last.length == 1
		return pairs
  end

  def self.range_query_data(field, val, boost=nil)
    # this is of the format ([+|-]match)+
    # we want to break it into its component parts
    pairs = self.make_pairs(val, /[\+-]/)

    results = []
    pairs.each {|pair|
      match = pair[1].sub(/\bto\b/i, 'TO')      # change '1700 to 1900' to '1700 TO 1900'
      match = "[#{match}]" if match.include?(' ') && !match.include?('"')
      results.push("#{boost ? '' : pair[0]}#{field}:#{match}#{boost ? "^#{boost}" : ''}")
    }
		puts "######### Result Year range_query_data: #{results.join(" ")}"
    return results.join(" ")
  end

	def self.insert_field_name(field, val, boost=nil, fuz=nil)
		# this is of the format ([+|-]match)+
		# we want to break it into its component parts
		pairs = self.make_pairs(val, /[\+-]/)

		results = []
		pairs.each {|pair|
      match = ''
      pair[1].split(/\s*\|\|\s*/).each{ |m|           # handle || symbol
        if !!m.match(/\W/) && !m.include?('"')  # check for non-word character
          match += "\"#{m}\""
        else
          match += "#{m}"
        end
        match += " || "
      }
      match.sub!(/ \|\| $/, '')

      if !!match.match(/\|\|/) and !match.match(/^\(.*\)$/)
        match = "(#{match})"
      end

      result = ''
      if boost.nil? and fuz.blank?
        result = "#{pair[0]}"
      end
      result += "#{field}:#{match}"
      # Skip fuzzy param if it is fuzzy 0 (exact match)
      if (not fuz.nil?) and fuz.to_i > 0 and !match.match(/\s/)  # we can't fuzzy search on a multi-word query
        result += "~#{fuz}"
      end
      if not boost.nil?
        result += "^#{boost}"
      end
      results.push(result)
		}
		return results.join(" ")
  end

  def self.insert_field_name_one_pair(field, val, boost=nil, fuz=nil)
    # this is of the format ([+|-]match)+
    # we want to break it into its component parts
    pairs = []
    if val.match(/^\+/)
      pairs.push(['+', val.sub(/^\+/, '')])
    elsif val.match(/^-/)
      pairs.push(['-', val.sub(/^-/, '')])
    end
    #pairs = self.make_pairs(val, /[\+-]/)

    results = []
    pairs.each {|pair|
      match = ''
      pair[1].split(/\s*\|\|\s*/).each{ |m|           # handle || symbol
        if !!m.match(/\W/) && !m.include?('"')  # check for non-word character
          match += "\"#{m}\""
        else
          match += "#{m}"
        end
        match += " || "
      }
      match.sub!(/ \|\| $/, '')

      if !!match.match(/\|\|/) and !match.match(/^\(.*\)$/)
        match = "(#{match})"
      end

      result = '';
      if boost.nil?
        result = "#{pair[0]}"
      end
      result += "#{field}:#{match}"
      if (not fuz.nil?) and !match.match(/\s/)  # we can't fuzzy search on a multi-word query
        result += "~#{fuz}"
      end
      if not boost.nil?
        result += "^#{boost}"
      end
      results.push(result)
      #results.push("#{boost ? '' : pair[0]}#{field}:#{match}#{fuz ? "~#{fuz}" : ''}#{boost ? "^#{boost}" : ''}")
    }
    return results.join(" ")
    #		str = val[1..val.length]
    #		str = "\"#{str}\"" if str.include?(' ')
    #		return "#{val[0]}#{field}:#{str}"
  end

	def self.transform_author(key,val)
    return { 'fq' => "+role_AUT:#{val.gsub('+', '')}" }
		# return { 'fq' => self.diacritical_query_data("author", val) }
		# val = val[1..val.length-1]
		# return { 'fq' => "+author:(#{val[1..val.length-1]})" }
	end

	def self.transform_coverage(key,val)
    return { 'fq' => "+coverage:#{val.gsub('+', ' ')}" }
    #self.diacritical_query_data("coverage", val) }
	end

	def self.transform_imprint(key,val)
		return { 'fq' => self.diacritical_query_data('publisher', val) }
		# return { 'fq' => "publisher:(#{self.diacritical_query_data('publisher', val)})" }
	end

  def self.transform_subject(key, val)
    return { 'fq' => self.diacritical_query_data('subject', val) }
  end

	def self.transform_abbreviatedTitle(key,val)
		return { 'fq' => self.diacritical_query_data("abbreviatedTitle", val) }
	end

	def self.transform_variantTitle(key,val)
		return { 'fq' => self.diacritical_query_data("variantTitle", val) }
	end

	def self.transform_earlierTitleProper(key,val)
		return { 'fq' => self.diacritical_query_data("earlierTitleProper", val) }
	end

	def self.transform_titleProperOfSeries(key,val)
		return { 'fq' => self.diacritical_query_data("titleProperOfSeries", val) }
	end

	def self.transform_title(key,val,fuz=nil)
	   #
	   # NOTE: The 'q' below was formerly 'fq' but this caused problems when searching
	   # for titles and including stop words. 'fq' queries break out the terms ( see solr:process_fq() )
	   # in the query for matches on each. Since stop words are filtered out, 
	   # all tile queries with them failed. Now title search works like normal 
	   # content serches except that is on the title / title_ascii field
	   #
		puts "inside transform_title #{val} #{fuz}"
		puts "THISTHISTHISTHISTHISTHIS333"
    #puts "starting q: " + val
    # correct protected character in URI queries
    #if key?('q')
      #if key.match(/*\w\d+/) 
        #val = 'queen'
      #end
    #end
    #puts "ending q: " + val
    puts "THISTHISTHISTHISTHISTHIS444"
		return { 'q' => self.diacritical_query_data("title", val, fuz) }
	end

	def self.transform_title_only(key, val, fuz=nil)
		puts "inside transform_title_only #{key} #{val} #{fuz}"
		return { 'fq' => self.diacritical_query_data("title", val) }
	end

	def self.transform_editor(key,val)
		return { 'fq' => self.diacritical_query_data("editor", val) }
	end

	def self.transform_publisher(key,val)
		return { "fq" => self.diacritical_query_data("publisher", val) }
	end

	def self.transform_year(key,val)
    return { 'fq' => self.range_query_data("year", val) }
  end

  def self.transform_role(key,val)
    return { 'fq' => self.insert_field_name(key , val) }
  end

  def self.transform_role_owner(key, val)
		return self.transform_role('role_OWN', val)
		# return { 'fq' => self.diacritical_query_data("role_OWN", val) }
  end

  def self.transform_role_repository(key, val)
		return self.transform_role('role_RPS', val)
		# return { 'fq' => self.diacritical_query_data("role_RPS", val) }
  end

  def self.transform_role_artist(key, val)
    return self.transform_role('role_ART', val)
  end

  def self.transform_role_generic(key, val)
    return self.transform_role(key, val)
  end

  def self.transform_language(key, val)
    return { 'fq' => self.insert_field_name_one_pair('language', val)}
  end

	def self.transform_archive(key,val)
		arc = val[1..-1]
		arc = "\"#{arc}\"" if arc.include?(' ')
		return { 'fq' => val[0] + "archive:" + arc }
	end

	def self.transform_genre(key,val)
		return { 'fq' => self.insert_field_name("genre", val) }
  end

  def self.transform_discipline(key,val)
    return { 'fq' => self.insert_field_name("discipline", val) }
  end

  def self.transform_doc_type(key,val)
    return { 'fq' => self.insert_field_name("doc_type", val) }
  end

	def self.transform_federation(key,val)
		# Federation comes in different from others. It has the the "federation:" tag already added. Also, it could have
		# OR clauses, which legitimatedly have spaces in them, so we want to suppress the quotifying.
		str = self.insert_field_name("federation", val.gsub("federation:", ""))
		str = str.gsub('"', '')
		return { 'fq' => str }
	end

	def self.transform_other(key,val)
		mapper = { 'freeculture' => 'freeculture', 'fulltext' => 'has_full_text', 'ocr' => 'is_ocr', 'typewright' => 'typewright' }
		pairs = self.make_pairs(val, /[\+-]/)
		results = []
		pairs.each {|pair|
			qualifier = pair[0]
			facet = mapper[pair[1]]
			results.push("#{qualifier}#{facet}:true") if !facet.blank?
		}
		return { 'fq' => results.join(' ') }
	end
	
	def self.transform_fq(key,val)
		return { 'fq' => val }
	end

  def self.transform_facet(key,val)
    val = val.split(',')
    facets = []
    val.each { |v|
      facets.push( v )
    }
    return { 'facet' => facets }
  end

  def self.transform_uri(key,val)
    val = val.split(',')
    uris = []
    val.each { |v|
      uris.push( v )
    }
    return { 'uri' => facets }
  end

  def self.transform_pivot( key,val )
    pivots = []
    pivots.push( "#{val},year_sort_asc" )
    pivots.push( "#{val},decade" )
    pivots.push( "#{val},quarter_century" )
    pivots.push( "#{val},half_century" )
    pivots.push( "#{val},century" )
    return { 'facet.pivot' => pivots }
  end

	def self.transform_sort(key,val)
		arr = val.split(' ')
		if arr[0] == 'last_modified'                       # Hack! this one parameter does not have a dedicated sort field.
      return { 'sort' => "#{arr[0]} #{arr[1]}" }
    elsif arr[0] == 'year'                             # Hack! solr cannot sort on date ranges so we have 2 fields reflecting the date range endpoints
      return { 'sort' => "#{arr[0]}_sort_#{arr[1]} #{arr[1]}" }
    else
			return { 'sort' => "#{arr[0]}_sort #{arr[1]}" }
		end
	end

	def self.transform_max(key,val)
		return { 'rows' => val }
	end

	def self.transform_highlight(key,val)
		if val == 'on'
			return { 'hl.fl' => 'text', 'hl.fragsize' => 600, 'hl.maxAnalyzedChars' => 512000, 'hl' => true, 'hl.useFastVectorHighlighter' => true }
		else
			return {}
		end
	end

	def self.transform_field(key,val)
    # check for non-word character and enclose in quotes
    val = "\"#{val}\"" if !!val.match(/\W/) && !val.include?('"')
		return { key => val }
	end

  def self.transform_last_modified(key, val)
    # check for space and enclose in quotes
    val = "\"#{val}\"" if !!val.match(/\s/) && !val.include?('"')
    return { key => val }
  end

	def self.transform_field_ascii(key,val)
		return { key => val + "" }
	end

	def self.transform_nil(key,val)
		return { }
	end

	def self.id_to_uri(id)
		return "$[FEDERATION_SITE]$/peer-reviewed-exhibit/#{id}"
	end

	def self.id_to_archive(id)
		return "exhibit_$[FEDERATION_NAME]$_#{id}"
	end

	def self.transform_id(key,val)
		return { :uri => "#{self.id_to_uri(val)}$[PAGE_NUM]$" }
	end

	def self.transform_frag(key,val)
		return { 'fragment' => val.gsub(/[^\p{Word} ]/u, '') }
	end

	def self.transform_max_matches(key,val)
		return { 'max' => val }
	end

	def self.transform_uri(key,val)
		val = "\"#{val}\"" if val.include?(' ')
		val = val.gsub("&amp;", "&")
		return { 'q' => "uri:#{val}" }
	end

	def self.transform_section(key, val)
		return { 'fq' => "section:#{val}" }
	end

	def self.trans_visible(typ, val)
		val = val.split(',')
		if val.length == 1
			val = val[0]
		else
			val = "(#{val.join(' OR ')})"
		end
		return { 'visible' => "visible_to_group_#{typ}:#{val}" }
	end

	def self.transform_group_membership(key, val)
		return self.trans_visible("member", val)
	end

	def self.transform_group_admin(key, val)
		return self.trans_visible("admin", val)
	end

	def self.transform_object_type(key, val)
		return { 'q' => "object_type:#{val}" }
	end

	def self.transform_group(key, val)
		return { 'q' => "group_id:#{val}" }
	end

	def self.create_solr_query(format, params, request_ip)
		# A raw parameter is one that is received by this web service.
		# It needs to be transformed into a solr parameter.
		# Format is a hash of a raw parameter that is one of the ones above.
		# Params are the raw parameters, as a hash with the key being the parameter.
		# We will transform them into query.
		# If a parameter doesn't match, an exception is thrown.
		# Defaults are added if it doesn't exist and a default was specified in the format.

		# If this isn't an authorized call, then only return free culture items.
		if request_ip && !Federation.request_from_federation(request_ip)
				if params['o'].blank?
					params['o'] = '+freeculture'
				else
					params['o'] = params['o'].gsub(/[+-]freeculture/, '') + '+freeculture'
				end
		end
		fuz_values = {}
		params.select{ |key, value| key.match(/^fuz_/) != nil}.each { |key, val|
	  
		definition = format[key]

		  raise(ArgumentError, "Unknown parameter: #{key}") if definition == nil
		  raise(ArgumentError, "Bad parameter (#{key}): (#{definition[:name]}) was passed as an array.") if val.kind_of?(Array) && definition[:can_be_array] != true
		  if val.kind_of?(Array)
			val.each { |v|
			  raise(ArgumentError, "11Bad parameter (#{key}): (#{v}). Must match: #{definition[:exp]}") if definition[:exp].match(v) == nil
			}
		  else
			raise(ArgumentError, "22Bad parameter (#{key}): (#{val}). Must match: #{definition[:exp]}") if definition[:exp].match(val) == nil
		  end
		  fuz_values[key.sub(/^fuz_/, '')] = val.sub(/[+-]/, '')
		}

		   query = {}
		   params.each { |key,val|
				val.gsub!(/^\+"'/,'+"');  # remove single quotes surrounded by double quotes
				val.gsub!(/'"$/,'"');
				
				definition = format[key]
				raise(ArgumentError, "Unknown parameter: #{key}") if definition == nil
				raise(ArgumentError, "33Bad parameter (#{key}): (#{definition[:name]}) was passed as an array.") if val.kind_of?(Array) && definition[:can_be_array] != true
				if val.kind_of?(Array)
					val.each { |v|
						raise(ArgumentError, "44Bad parameter (#{key}): (#{v}). Must match: #{definition[:exp]}") if definition[:exp].match(v) == nil
					}
				else
					puts "Fail point 4"
					# raise(ArgumentError, "55Bad parameter (#{key}): (#{val}). Must match: #{definition[:exp]}") if definition[:exp].match(val) == nil
				end

				if definition[:can_fuz]
					if fuz_values[key]
						solr_hash = definition[:transformation].call(key,val, fuz_values[key])
					else
						solr_hash = definition[:transformation].call(key,val, nil)
					end
				else
					solr_hash = definition[:transformation].call(key,val)
				end

				# solr_hash = { 'title' => '+clara' } if key == 't'
				query.merge!(solr_hash) {|k, oldval, newval|
						oldval + " " + newval
				}
			}
		
			# add defaults
			format.each { |key, definition|
				if params[key] == nil && definition[:default] != nil
					solr_hash = definition[:transformation].call(key,definition[:default])
					query.merge!(solr_hash) {|k, oldval, newval|
						oldval + " " + newval
					}
				end
			}

			# add standard boosts
			#query[:bq] = 'genre:Citation^0.1'
			
			puts "UUUUUUUUUUUUUUUUUUU"
			puts query
			puts "UUUUUUUUUUUUUUUUUUU"

			return query
	    end
end
