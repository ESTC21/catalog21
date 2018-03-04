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

require 'fileutils'
require "#{Rails.root}/lib/tasks/task_reporter.rb"
require "#{Rails.root}/lib/tasks/task_utilities.rb"

namespace :solr_index do
	include TaskUtilities

=begin
	def get_folders(path, archive)
		folder_file = File.join(path, "sitemap.yml")
		site_map = YAML.load_file(folder_file)
		rdf_folders = site_map['archives']
    rdf_folders = rdf_folders.reject {|k, v| v.nil? }

    puts "## #{rdf_folders}"
		# all_enum_archives = {}
		# rdf_folders.each { |k, f|
     #  puts "FFF: #{f}"
		# 	if f.kind_of?(String)
		# 		all_enum_archives[k] = f
		# 	else
		# 		all_enum_archives.merge!(f)
		# 	end
		# }
		# folders = all_enum_archives[archive]
		# if folders == nil
		# 	return {:error => "The archive \"#{archive}\" was not found in #{folder_file}"}
		# end
		# return {:folders => ['estc_new_rdf'], :page_size => 1000}
		return {:folders => folders[0].split(';'), :page_size => folders[1]}
		return {:folders => ['estc_new_rdf'], :page_size => 1000}
	end
=end

	def get_folders(path, archive)
		folder_file = File.join(path, "sitemap.yml")
		site_map = YAML.load_file(folder_file)
		rdf_folders = site_map['archives']
		all_enum_archives = {}
		rdf_folders.each { |k, f|
			puts "looping :K: #{k} ... :F: #{f}"
			if f.kind_of?(String)
				puts '-- if'
				all_enum_archives[k] = f
			else
				puts '-- if'
				all_enum_archives.merge!(f)
			end
		}
		puts "-- all_enum_archives[archive]:: #{all_enum_archives[archive]}"
		folders = all_enum_archives[archive]
		if folders == nil
			return {:error => "The archive \"#{archive}\" was not found in #{folder_file}"}
		end
		puts "-- folders[0].split(';'):: #{folders[0].split(';')} _ folders[1]:: #{folders[1]}"
		return {:folders => folders[0].split(';'), :page_size => folders[1]}
	end

	desc "create complete reindexing task list"
	task :create_reindexing_task_list => :environment do

		folder_file = File.join(RDF_PATH, "sitemap.yml")
		site_map = YAML.load_file(folder_file)
		rdf_folders = site_map['archives']

		# the archives found need to exactly match the archives in the site maps.
		all_enum_archives = {}
		rdf_folders.each do |k,f|
			all_enum_archives.merge!(f)
		end

      # create batch files
		sh_clr = create_sh_file("clear_archives")
		sh_merge = create_sh_file("merge_all")
      sh_all = create_sh_file("batch_all")
      sh_all.puts("TASK=solr_index:index_and_test\n")

		merge_list = []
		rdf_folders.each do |i, rdfs|
		   # batch number and yml data about archives in the batch
			if i.kind_of?(Fixnum)
				sh_rdf = create_sh_file("batch#{i+1}")
				sh_rdf.puts("TASK=solr_index:index_and_test\n")
				merge_list_section = []

				rdfs.each do |archive,f|
				   # archive name and info [dir_name, size_limit]
					sh_clr.puts("curl #{SOLR_URL}/#{archive}/update?stream.body=%3Cdelete%3E%3Cquery%3E*:*%3C/query%3E%3C/delete%3E\n")
					sh_clr.puts("curl #{SOLR_URL}/#{archive}/update?stream.body=%3Ccommit%3E%3C/commit%3E\n")

					sh_rdf.puts("rake \"archive=#{archive}\" $TASK\n")
					sh_all.puts("rake \"archive=#{archive}\" $TASK\n")

					merge_list.push(archive)
					merge_list_section.push(archive)
				end

				sh_rdf.close()
				sh_merge_list_section = create_sh_file("merge#{i+1}")
				sh_merge_list_section.puts("rake solr_index:merge_archive archive=\"#{merge_list_section.join(',')}\"")
				sh_merge_list_section.close()
			end
		end

		sh_clr.close()
		if merge_list.length > 0
			sh_merge.puts("rake solr_index:merge_archive archive=\"#{merge_list.join(',')}\"")
		end

		sh_merge.puts("rake solr:optimize core=resources")
		sh_merge.close()
		sh_all.close()
	end

	def index_archive(msg, archive, type, append=false)
		flags = nil
		case type
			when :spider
				flags = "-mode spider"
				puts "~~~~~~~~~~~ #{msg} \"#{archive}\" [see log/progress/#{archive}_progress.log and log/#{archive}_spider_error.log]"
			when :index
				puts "!!!!!! #{append == false}"
				flags = "-mode index #{'-delete' unless append}"
				puts "~~~~~~~~~~~ #{msg} \"#{archive}\" [see log/progress/#{archive}_progress.log and log/#{archive}_error.log]"
			when :debug
				flags = "-mode test"
				puts "~~~~~~~~~~~ #{msg} \"#{archive}\" [see log/progress/#{archive}_progress.log and log/#{archive}_error.log]"
			when :resolve
				flags = "-mode resolve"
				puts "~~~~~~~~~~~ #{msg} \"#{archive}\" [see log/progress/#{archive}_progress.log and log/#{archive}_error.log]"
		end

		if flags == nil
			puts "Call with either :spider, :index, :resolve or :debug"
		else
			folders = get_folders(RDF_PATH, archive)
			puts "folders ::: "
			puts folders
			if folders[:error]
				puts folders[:error]
			else
				safe_name = Solr::archive_to_core_name(archive)
puts "123~~~~~~~~~~~ safe_name: \"#{safe_name}\""




        # The problem is below.  The indexer_path value is wrong
        # need to figure out where this is coming from and
        # correct it.




				log_dir = "#{Rails.root}/log"
				case type
					when :spider
						delete_file("#{log_dir}/#{safe_name}_spider_error.log")
					when :index, :debug
						delete_file("#{log_dir}/#{safe_name}_error.log")
				end
				delete_file("#{log_dir}/progress/#{safe_name}_progress.log")
				delete_file("#{log_dir}/#{safe_name}_error.log")
				delete_file("#{log_dir}/#{safe_name}_link_data.log")
				delete_file("#{log_dir}/#{safe_name}_duplicates.log")

				folders[:folders].each { |folder|
					puts "11111111111111****************************************************"
					puts "cd #{indexer_path()} && java -Xmx3584m -jar #{indexer_name()} -logDir \"#{log_dir}\" -source \"#{RDF_PATH}/#{folder}\" -archive \"#{archive}\" #{flags}"
					puts "xxxxxxxxxxxxxxxxxxxx"
          puts "cd #{INDEXER_PATH} && java -Xmx3584m -jar #{indexer_name()} -logDir \"#{log_dir}\" -source \"#{RDF_PATH}/#{folder}\" -archive \"#{archive}\" #{flags}"
          puts "11111111111111*****************************************************"
					#cmd_line("cd #{indexer_path()} && java -Xmx3584m -jar #{indexer_name()} -logDir \"#{log_dir}\" -source \"#{RDF_PATH}/#{folder}\" -archive \"#{archive}\" #{flags}")
          cmd_line("cd #{INDEXER_PATH} && java -Xmx3584m -jar #{indexer_name()} -logDir \"#{log_dir}\" -source \"#{RDF_PATH}/#{folder}\" -archive \"#{archive}\" #{flags}")
        }
			end
		end
	end

	def compare_indexes_java (archive, page_size = 100, mode = nil)
puts "~~~~~~~~~~~ compare_indexes_java \"#{page_size}\" "

		flags = ""
		safe_name = Solr::archive_to_core_name(archive)
		log_dir = "#{Rails.root}/log/index"

		# no mode specified = full compare on al fields.
		# delete all log files
		if mode.nil?
			delete_file("#{log_dir}/#{safe_name}_compare.log")
			delete_file("#{log_dir}/#{safe_name}_compare_text.log")
		else
			# if just txt compare is requested, ony delete txt log
			if mode == "compareTxt"
				flags = "-include text"
				delete_file("#{log_dir}/#{safe_name}_compare_text.log")
			end

			# if non-txt compare is requested, only delete the compare log
			if mode == "compare"
				flags = "-ignore text"
				delete_file("#{log_dir}/#{safe_name}_compare.log")
			end
		end

		# skipped is always deleted
		delete_file("#{log_dir}/#{safe_name}_skipped.log")

		# launch the tool
		puts "22222222222222222222****************************************************"
		cmd_line("cd #{indexer_path()} && java -Xmx3584m -jar #{indexer_name()} -logDir \"#{log_dir}\" -archive \"#{archive}\" -mode compare #{flags} -pageSize #{page_size}")

	end

	def test_archive(archive)
		puts "~~~~~~~~~~~ testing \"#{archive}\" [see log/#{archive}_*.log]"
		folders = get_folders(RDF_PATH, archive)
		if folders[:error]
			puts "The archive entry for \"#{archive}\" was not found in any sitemap.yml file."
		else
				folders[:folders].each {|folder|
					find_duplicate_uri(folder, archive)
				}



			page_size = folders[:page_size].to_s
puts "~~~~~~~~~~~ duplicate check done \"#{page_size}\" "
			compare_indexes_java(archive, page_size)
		end
	end

	def do_archive(split = :split)
		archive = ENV['archive']
		append = ENV['append']

		if archive == nil
			puts "Usage: call with archive=XXX,YYY"
		else
			start_time = Time.now
			append = false if append.nil?
			append = (append == 'true' ? true : false)

			if split == :split
				archives = archive.split(',')
				archives.each { |a| yield a, append }
			else
				yield archive, append
			end
			finish_line(start_time)
		end
	end

	def find_duplicate_uri(folder, archive)
		puts "~~~~~~~~~~~ Searching for duplicates in \"#{RDF_PATH}/#{folder}\" ..."
		puts "creating folder list..."
		directories = get_folder_tree("#{RDF_PATH}/#{folder}", [])

		directories.each { |dir|
			TaskReporter.set_report_file("#{Rails.root}/log/#{Solr.archive_to_core_name(archive)}_duplicates.log")
			puts "scanning #{dir} ..."
			all_objects_raw = `find #{dir}/* -maxdepth 0 -print0 | xargs -0 grep "rdf:about"` # just do one folder at a time so that grep isn't overwhelmed.
			all_objects_raw = all_objects_raw.split("\n")
			all_objects = {}
			all_objects_raw.each { |obj|
				arr = obj.split(':', 2)
				next if arr[0].include? ".ORIG_RDF"
				arr1 = obj.split('rdf:about="', 2)
				arr2 = arr1[1].split('"')
				if all_objects[arr2[0]] == nil
					all_objects[arr2[0]] = arr[0]
				else
					TaskReporter.report_line("Duplicate: #{arr2[0]} in #{all_objects[arr2[0]]} and #{arr[0]}")
				end
			}
		}
	end

	def merge_archive(archive)
		puts "~~~~~~~~~~~ Merging archive(s) #{archive} ... (this may take some time, please be patient)"
		archives = archive.split(',')
		archive_list = []
      solr_archives = Solr.factory_create(:live)

		page_list = []
      solr_pages = Solr.factory_create(:pages)

		archives.each do |arch|
			index_name = Solr.archive_to_core_name(arch)
			if index_name.index("pages_") == 0
			   solr_pages.remove_archive(arch, false)
			   page_list.push(index_name)
			else
            solr_archives.remove_archive(arch, false)
			   archive_list.push("archive_#{index_name}")
			end
		end

		solr_archives.merge_archives(archive_list) if !archive_list.empty?
      solr_pages.merge_archives(page_list) if !page_list.empty?
	end

	#############################################################
	## TASKS
	#############################################################

	desc "Look for duplicate objects in rdf folders (param: folder=subfolder_under_rdf,archive)"
	task :find_duplicate_objects => :environment do
		folder = ENV['folder']
		arr = folder.split(',') if folder
		if arr == nil || arr.length != 2
			puts "Usage: call with folder=folder,archive"
		else
			folder = arr[0]
			archive = arr[1]
			start_time = Time.now
			find_duplicate_uri(folder, archive)
			finish_line(start_time)
		end
	end

	desc "Index documents from the rdf folder to the reindex core (param: archive=XXX,YYY append=true/false)"
	task :index  => :environment do
		do_archive { |archive, append| index_archive("Index", archive, :index, append) }
	end

	desc "Test one RDF archive (param: archive=XXX,YYY)"
	task :archive_test => :environment do
		do_archive { |archive| test_archive(archive) }
	end

	desc "Do the initial indexing of a folder to the archive_* core (param: archive=XXX,YYY)"
	task :debug => :environment do
		do_archive { |archive| index_archive("Debug", archive, :debug) }
	end

	desc "Index and test one rdf archive (param: archive=XXX,YYY append=true/false)"
	task :index_and_test => :environment do
		do_archive { |archive, append|
			index_archive("Index", archive, :index, append)
			test_archive(archive)
		}
	end

	desc "Resolve any document references (isPartOf, hasPart) in the specified archive (param: archive=XXX,YYY)"
	task :resolve  => :environment do
		do_archive { |archive| index_archive("Resolve", archive, :resolve) }
	end

	desc "Spider the archive for the full text and place results in rawtext. No indexing performed. (param: archive=XXX,YYY)"
	task :spider_rdf_text => :environment do
		do_archive { |archive| index_archive("Spider text", archive, :spider) }
	end

	desc "Merge archives into the \"resources\" or \"pages\" index (param: archive=XXX,YYY)"
	task :merge_archive => :environment do
		do_archive(:as_one) { |archives| merge_archive(archives) }
	end

	desc "Package archives and send them to a server. (archive=XXX,YYY) This gets them ready to be installed on the other server with the sister script: solr_index:install"
   task :package => :environment do
      do_archive { |archive|
         if "#{archive}" == "EEBO" or "#{archive}" == "TEST_RDF"
            puts "Archive #{archive} is a test archive and is not ready to be packaged."
         else
            # if this is a pages archive, do NOT prepend it with archive_
            if archive.index("pages_") == 0
               index = archive
            else
               index = "archive_#{archive}"
            end

            filename = backup_archive(index)
            send_method = Rails.application.secrets.folders['tasks_send_method']
            if send_method == 'cp'
               FileUtils.cp(filename, dest_filename_of_zipped_index(index))
            else
               Net::SCP.start(Rails.application.secrets.production['ssh_host'], Rails.application.secrets.production['ssh_user']) do |scp|
                  scp.upload! filename, dest_filename_of_zipped_index(index)
               end
            end
         end
      }
   end

	desc "Package the main archive and send it to a server. (archive=XXX,YYY) This gets it ready to be installed on the other server with the sister script: solr:install"
   task :package_resources => :environment do
      filename = backup_archive('resources')
      send_method = Rails.application.secrets.folders['tasks_send_method']
      if send_method == 'cp'
         FileUtils.cp(filename, dest_filename_of_zipped_index('resources'))
      else
         Net::SCP.start(Rails.application.secrets.production['ssh_host'], Rails.application.secrets.production['ssh_user']) do |scp|
            scp.upload! filename, dest_filename_of_zipped_index('resources')
         end
      end
   end

	desc "This assumes a list of gzipped archives in the #{Rails.application.secrets.folders['uploaded_data']} folder named like this: archive_XXX.tar.gz. (params: archive=XXX,YYY) It will add those archives to the resources index."
   task :install => :environment do
      indexes = []
      pages = []
      solr_live = Solr.factory_create(:live)
      solr_pages = Solr.factory_create(:pages)
      solr = nil
      do_archive { |archive|
         folder = Rails.application.secrets.folders['uploaded_data']

         if archive.index("pages_") == 0
            index = archive
            index_path = "#{folder}/#{index}"
            solr = solr_pages
            pages.push(index_path)
         else
            index = "archive_#{archive}"
            index_path = "#{folder}/#{index}"
            solr = solr_live
            indexes.push(index_path)
         end

         cmd_line("cd #{folder} && tar xvfz #{index}.tar.gz")
         cmd_line("rm -r -f #{index_path}")
         cmd_line("mv #{uploaded_data_index} #{index_path}")
         File.open("#{Rails.root}/log/archive_installations.log", 'a') {|f| f.write("Installed: #{Time.now().getlocal().strftime("%b %d, %Y %I:%M%p")} Created: #{File.mtime(index_path).getlocal().strftime("%b %d, %Y %I:%M%p")} #{archive}\n") }
         solr.remove_archive(archive, false)
      }

      if indexes.length > 0
         delete_file("#{Rails.root}/cache/num_docs.txt")
         solr_live.merge_archives(indexes, false)
      end
      if pages.length > 0
         delete_file("#{Rails.root}/cache/num_docs.txt")
         solr_pages.merge_archives(pages, false)
      end
   end

desc "removes archives from the resources or pages index (param: archive=XXX,YYY)"
   task :remove  => :environment do
      pages_cnt = 0
      other_cnt = 0
      do_archive do |archive|
         if archive.index("pages_") == 0
            pages_cnt += 1
         else
            other_cnt += 1
         end
      end

      if pages_cnt > 0 && other_cnt > 0
         raise "\n\nCannot mix removal of pages/non-pages archives.\nPlease make separate requests for each archive type.\n\n"
      end

      if pages_cnt > 0
        puts "Removing pages archives"
        solr = Solr.factory_create(:pages)
      else
        puts "Removing non-pages archives"
        solr = Solr.factory_create(:live)
      end

      do_archive do |archive|
         puts "  * #{archive}"
         solr.remove_archive(archive, false)
      end

      if !solr.blank?
         puts " * SOLR commit..."
         solr.commit()
      end
      puts "DONE!"
   end

	desc "removes all exhibits from the resources index"
	task :delete_exhibits => :environment do
		solr = Solr.factory_create(:live)
		archives = solr.get_archive_list()
		archives.each { |archive|
			if archive.index('exhibit_') == 0
				puts archive
				solr.remove_archive(archive, false)
			end
		}
		solr.commit()
		solr.optimize()
	end

	desc "Clean archive text and place results in fulltext, ready for indexing; No indexing performed; (param: archive=XXX,YYY)"
	task :clean_text => :environment do
		do_archive { |archive|
			safe_name = Solr::archive_to_core_name(archive)
			log_dir = "#{Rails.root}/log"
			delete_file("#{log_dir}/progress/#{safe_name}_progress.log")
			delete_file("#{log_dir}/#{safe_name}_clean_raw_error.log")
			case archive
				when 'cali'
					source = 'fulltext'
					mode = 'clean_full'
					custom = '-custom CaliCleaner'
				when 'locEphemera'
					source = 'rawtext'
					mode = 'clean_raw'
					custom = '-custom LocEphemeraCleaner'
				when 'ncaw'
					source = 'rawtext'
					mode = 'clean_raw'
					custom = '-custom NcawCleaner'
				when 'nineteen'
					source = 'rawtext'
					mode = 'clean_raw'
					custom = '-custom NineteenCleaner'
				when 'WrightAmFic'
					source = 'rawtext'
					mode = 'clean_raw'
					custom = '-custom WrightAmFicCleaner'
        when 'walters'
          source = 'rawtext'
          mode = 'clean_raw'
          custom = ''
				else
					puts "WARNING: No custom text cleaning was defined for this archive!"
					source = 'rawtext'
					mode = 'clean_raw'
					custom = ''
			end
			puts "3333333333333333333333333****************************************************"
			cmd_line("cd #{indexer_path()} && java -Xmx3584m -jar #{indexer_name()} -logDir \"#{log_dir}\" -source #{RDF_PATH}/../#{source} -archive \"#{archive}\" -mode #{mode} #{custom}")
		}
	end

end
