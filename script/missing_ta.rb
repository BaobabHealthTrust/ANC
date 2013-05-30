
class MissingTa
  def self.startImport

    district_filenames = Dir.entries("public/data/missing_ta") rescue []

    district_filenames.each do |d_filename|

      next if (d_filename.to_s.length < 4 rescue true) || district_id(d_filename).blank?

      ta_filenames = Dir.entries("public/data/missing_ta/#{d_filename}") rescue []

      ta_filenames.each do |t_filename|

        next if (t_filename.to_s.length < 4 rescue true) || t_filename.match("~")

        file =  File.open(RAILS_ROOT + "/public/data/missing_ta/#{d_filename}/#{t_filename}", "r") rescue nil

        file.each{ |village|

          ta_name = t_filename.split(".")[0]
          #create missing ta and villages
          district_of_interest = district_id(d_filename)
          next if district_of_interest.blank? || village.blank?

          write_ta(ta_name, district_of_interest) if ta_id(ta_name, district_of_interest).blank?
          tr_authority_id = ta_id(ta_name, district_of_interest)

          next if tr_authority_id.blank? || (village_id(village, tr_authority_id).present? )

          if village_id(village.strip, tr_authority_id).blank?
            write_village(village, tr_authority_id)
            puts "Added  #{d_filename} => #{ta_name} => #{village}"
          end
        }

      end

    end

  end

  def self.district_id(ds)

    District.find_by_name(ds).district_id rescue nil

  end

  def self.ta_id(ta, district)

    TraditionalAuthority.find_by_name_and_district_id(ta, district).traditional_authority_id rescue nil

  end

  def self.village_id(vg, ta)

    Village.find_by_name_and_traditional_authority_id(vg, ta).village_id rescue nil

  end

  def self.write_district(ds, region)

    usr = User.find_by_username("admin").user_id

    district_id = district_id(ds)
    district_full = District.find(district_id) rescue nil

    if district_full.blank?
      District.create(:name => ds.strip,
        :region_id => region,
        :date_created => Date.today,
        :creator => usr)
    else
      district_full.update_attributes(:name => ds.strip,
        :region_id => region,
        :creator => usr)
    end

  end

  def self.write_ta(ta, district)
    usr = User.find_by_username("admin").user_id

    ta_id = ta_id(ta, district)
    ta_full = TraditionalAuthority.find(ta_id) rescue nil

    if ta_full.blank?
      TraditionalAuthority.create(:name => ta.strip,
        :district_id => district,
        :date_created => Date.today,
        :creator => usr)
    else
      ta_full.update_attributes(:name => ta.strip,
        :district_id => district,
        :creator => usr)
    end
  end

  def self.write_village(vg, ta)
    usr = User.find_by_username("admin").user_id

    vg_id = village_id(vg, ta)
    vg_full = Village.find(vg_id) rescue nil

    if vg_full.blank?
      Village.create(:name => vg.strip,
        :traditional_authority_id => ta,
        :date_created => Date.today,
        :creator => usr)
    else
      vg_full.update_attributes(:name => vg,
        :traditional_authority_id => ta,
        :creator => usr)
    end
  end

  start = Time.now
  puts "Started at #{start}"

  startImport

  puts "Started at: #{start} - Finished at:#{Time.now()}"

end

