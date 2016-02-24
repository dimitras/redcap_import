# USAGE:
# ruby to_redcap.rb "30" phase1day1.csv
# ruby to_redcap.rb "test subject 1" phase2day7.csv

#export  file with records by cols
#for each subject > 15 events > 15x8 forms with multiple fields, BUT each import file can contain only one event

require 'rubygems'
require 'csv'

subj_id = ARGV[0] # identified id "test subject 1"
isamples = ARGV[1] #phaseX_dayX.csv

events_list = {
	"Phase1 Day1" => "phase_1_treatment_arm_1",
	"Phase1 Day7" => "phase_1_treatment_arm_1g",
	"Phase1 Day8" => "phase_1_posttreatm_arm_1",
	"Phase1 Day9" => "phase_1_posttreatm_arm_1b",
	"Phase1 Day10" => "phase_1_posttreatm_arm_1c",
	"Phase2 Day1" => "phase_2_treatment_arm_1",
	"Phase2 Day7" => "phase_2_treatment_arm_1g",
	"Phase2 Day8" => "phase_2_posttreatm_arm_1",
	"Phase2 Day9" => "phase_2_posttreatm_arm_1b",
	"Phase2 Day10" => "phase_2_posttreatm_arm_1c",
	"Phase3 Day1" => "phase_3_treatment_arm_1",
	"Phase3 Day7" => "phase_3_treatment_arm_1g",
	"Phase3 Day8" => "phase_3_posttreatm_arm_1",
	"Phase3 Day9" => "phase_3_posttreatm_arm_1b",
	"Phase3 Day10" => "phase_3_posttreatm_arm_1c"
}

# read the dict (format: redcap field, collos field, tissue, timepoint, id)
dict_list = Hash.new { |h,k| h[k] = {} }
dict_name = isamples.split("_")[1]
CSV.foreach("dictionaries/#{dict_name}") do |row|
	if !row[0].include? "REDCAP"
		if !dict_list.has_key?(row[0])
			dict_list[row[0]] = {:collos=>row[1], :tissue=>row[2], :timepoint=>row[3], :id=>row[4].to_i}
		end
	end
end

# sort the dictionary
#eg: {"post_urine_freezer_label"=>{:tissue=>"urine", :timepoint=>"post-treatment", :id=>435, :collos=>"freezer_label"},}
sorted_dict = dict_list.sort_by{|key, val| val[:id]}
keys =[]
values = []
sorted_dict.each do |redcap_key|
	keys << redcap_key[0]
	values << redcap_key[1]
end

# read the sample list (format: sample_collos_id	sample_identifier	id_barcode	id_subject	id_study	sample_type	collection-time-point	treatment	sample_name	species	material_type	container_type	box_label box_barcode	freezer_label	freezer_type	type)
samples_list = Hash.new { |h,k| h[k] = [] }
CSV.foreach("collos_exports/#{isamples}") do |row|
	if (!row[0].include? "sample_collos_id")
		if row[3]!= ""
			samples_list[row[3]] << {:id_barcode=>row[2], :id_subject=>row[3], :id_study=>row[4], :sample_type=>row[5], :collection_time_point=>row[6], :treatment=>row[7], :sample_name=>row[8], :box_barcode=>row[13], :freezer_label=>row[14], :freezer_type=>row[15]}
		end
	end
end

# output
CSV.open("to_import/import_#{isamples}", "w") do |csv|
	samples_list.each do |subject, samples|
		in_tp = false
		event_more_than_one = false
		id = 1
		samples.each do |sample|
			(phase, day, tp) = sample[:collection_time_point].split(" ")
			phase_day = "#{phase} #{day}"
			if !tp.nil?
				day_tp = "#{day} #{tp}"
			elsif tp.nil?
				day_tp = day
			end	

			if events_list.has_key?(phase_day)
				event = events_list[phase_day]

				if in_tp == false
					in_tp = true
					p "IN: #{in_tp} SUBJ: #{subject} TP: #{phase_day} STUDY: #{sample[:id_study]} ID: #{id-1}"
					csv << [keys[id-1], subj_id]
					p "Subject id = #{id-1}"
					id +=1
				end

				if (event_more_than_one == false) && (keys[id-1] == "redcap_event_name") && (day_tp == values[id][:timepoint])
					p "TP: #{phase_day} EV: #{event} ID: #{id-1}"
					csv << ["redcap_event_name", event]
					p "Event id = #{id-1} EVENT: #{event}"
					event_more_than_one = true
					id +=1
				end

				if values[id] && (sample[:sample_type] == values[id][:tissue]) && (day_tp == values[id][:timepoint])
					p "CHECK id = #{id-1} - #{values[id][:tissue]} ?= #{sample[:sample_type]} AND #{day_tp} ?= #{values[id-1][:timepoint]}"

					if values[id-1][:collos] == "collection_time_point"
						p "TP id = #{id-1}"
						id +=1
					end

					if (keys[id-1].include? "aliquots") || (values[id-1][:collos].is_a? Integer)
						csv << [keys[id-1], values[id-1][:collos]]
						p "ALQ id = #{id-1}"
						id +=1
					end
					
					if values[id-1][:collos] == "id_barcode"
						if values[id][:collos] == "id_barcode"
							csv << [keys[id-1], sample[:id_barcode]]
							p "Sample id* = #{id+1} - bar = #{sample[:id_barcode]}" 
							id +=1
							next
						end
						csv << [keys[id-1], sample[:id_barcode]]
						p "Sample id = #{id-1} - bar = #{sample[:id_barcode]}"
						id +=1
					end

					if values[id-1][:collos] == "box_barcode"
						csv << [keys[id-1], sample[:box_barcode]]
						p "Box id = #{id-1}"
						id +=1
						if values[id-1][:collos] != "freezer_type"
							retry
						end
					end

					if values[id-1][:collos] == "freezer_type"
						if sample[:freezer_type] == "Refrigerator/freezer (4C)"
							csv << [keys[id-1], 1]
						elsif sample[:freezer_type] == "-20 freezer"
							csv << [keys[id-1], 2]
						elsif sample[:freezer_type] == "-30 freezer"
							csv << [keys[id-1], 3]
						elsif sample[:freezer_type] == "-80 freezer"
							csv << [keys[id-1], 4]
						elsif sample[:freezer_type] == "Liquid nitrogen tank"
							csv << [keys[id-1], 5]
						end
						p "FreezerT id = #{id-1}"
						id +=1
					end

					if values[id-1][:collos] == "freezer_label"
						csv << [keys[id-1], sample[:freezer_label]]
						p "FreezerL id = #{id-1}"
						id +=1
						if values[id-1][:collos] != "treatment"
							retry
						end
					end

					if values[id-1][:collos] == "treatment"
						csv << [keys[id-1], sample[:treatment]]
						p "Treat id = #{id-1}"
						id +=1
						retry
					end
				end
			end
		end
	end
end
