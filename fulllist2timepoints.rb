# USAGE: ruby fulllist2timepoints.rb FULLEXPORTFROMCOLLOS.csv

require 'rubygems'
require 'csv'

ifile = ARGV[0]

# read the full collos export : all samples of a study
full_list = Hash.new { |h,k| h[k] = [] }
files_list = []
CSV.foreach(ifile) do |row|
	if (!row[0].include? "sample_collos_id") && (row[3] != "")
		full_list[row[3]] << {:sample_collos_id=>row[0], :sample_identifier=>row[1], :id_barcode=>row[2], :id_subject=>row[3], :id_study=>row[4], :sample_type=>row[5], :collection_time_point=>row[6], :treatment=>row[7], :sample_name=>row[8], :species=>row[9], :material_type=>row[10], :quantity=>row[11], :box_label=>row[12], :box_barcode=>row[13], :freezer_label=>row[14], :freezer_type=>row[15], :type=>row[16]}
		if match = row[6].match(/(\Phase\d)\s(\Day\d*)\s*\w*/i)
			phase, day = match.captures
			fname = "#{phase}_#{day}"
			files_list << fname
		end
	end
end



# split to separate files per subject, per phase, per day
full_list.each do |subject, samples|
	files_list.uniq.each do |f|
		Dir.mkdir("collos_exports/#{subject}") unless File.exists?("collos_exports/#{subject}")
		(fphase, fday) = f.split("_")

		# export a file for each phase
		CSV.open("collos_exports/#{subject}/#{fphase}.csv", "w") do |csv|
			csv << ["sample_collos_id","sample_identifier","id_barcode","id_subject","id_study","sample_type","collection-time-point","treatment","sample_name","species","material_type","quantity","box_label","box_barcode","freezer_label","freezer_type","type"]
			samples.each do |sample|
				(phase, day, tp) = sample[:collection_time_point].split(" ")
				if phase == fphase
					csv << [sample[:sample_collos_id], sample[:sample_identifier], sample[:id_barcode], sample[:id_subject], sample[:id_study], sample[:sample_type], sample[:collection_time_point], sample[:treatment], sample[:sample_name], sample[:species], sample[:material_type], sample[:quantity], sample[:box_label], sample[:box_barcode], sample[:freezer_label], sample[:freezer_type], sample[:type]]
				end
			end
		end

		# split to separate files per subject, per phase, per day
		CSV.open("collos_exports/#{subject}/#{f.downcase}.csv", "w") do |csv|
			csv << ["sample_collos_id","sample_identifier","id_barcode","id_subject","id_study","sample_type","collection-time-point","treatment","sample_name","species","material_type","quantity","box_label","box_barcode","freezer_label","freezer_type","type"]
			samples.each do |sample|
				(phase, day, tp) = sample[:collection_time_point].split(" ")
				if phase == fphase && day == fday
					csv << [sample[:sample_collos_id], sample[:sample_identifier], sample[:id_barcode], sample[:id_subject], sample[:id_study], sample[:sample_type], sample[:collection_time_point], sample[:treatment], sample[:sample_name], sample[:species], sample[:material_type], sample[:quantity], sample[:box_label], sample[:box_barcode], sample[:freezer_label], sample[:freezer_type], sample[:type]]
				end
			end
		end
	end
end