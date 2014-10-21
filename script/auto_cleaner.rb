#The first method cleans encounters with wrong date by replacing with the correct obs date time.

def fix_encounter_datetimes

  ActiveRecord::Base.connection.execute("UPDATE obs o
      INNER JOIN encounter e ON e.encounter_id = o.encounter_id
      SET  o.obs_datetime = e.encounter_datetime
      WHERE DATE(e.encounter_datetime) != DATE(o.obs_datetime)")
  puts "Done"
end

def clean
  #all method calls to be added here

  puts "Fixing wrong encounter dates"
  fix_encounter_datetimes
end

clean


