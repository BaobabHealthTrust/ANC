class PersonNamesController < ApplicationController
  def family_names
    search("family_name", params[:search_string])
  end

  def given_names
    search("given_name", params[:search_string])
  end

  def family_name2
    search("family_name2", params[:search_string])
  end

  def search(field_name, search_string)
    if search_string.blank?
      names = PersonNameCode.find_top_ten(field_name).collect{|person_name| person_name.send(field_name)}
    else
      names = PersonNameCode.find_most_common(field_name, search_string).collect{|person_name| person_name.send(field_name)}
    end
    result = "<li>" + names.map{|n| n } .join("</li><li>") + "</li>"
    render :text => result
  end
end
