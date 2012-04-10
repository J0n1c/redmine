namespace :fix do
  task :date_problem, [:key] => :environment do |cmd,args|
    desc "Extracts date from message and puts it into appropriate field [with key --fix]"

    process_the_data Issue,   args[:key]
    process_the_data Journal, args[:key]

  end
end

def process_the_data model, key
  include ActionController::UrlWriter
  header_regexp = /^Date: (\w{3} \w{3} \d\d \d\d:\d\d:\d\d [+-]\d{4} \d{4})(.*)$/m
  default_url_options[:host] = YAML::load(File.open("#{RAILS_ROOT}/config/settings.yml"))["host_name"]["default"]
  date_format = "%a %b %d %H:%M:%S %z %Y"
  model.all.each do |one_record|
    matches = header_regexp.match model==Issue ? one_record.description : one_record.notes
    if matches
      url=url_for :controller => 'issues',:action => 'show',:id => model==Issue ? one_record : one_record.journalized_id
      in_date = DateTime.strptime(matches[1], date_format)
      puts "#{url}\t#{in_date.strftime("%Y-%m-%d %H:%M:%S %z")}"
      if key == "--fix"
        one_record.created_on = in_date
        model==Issue ? one_record.description : one_record.notes = matches[2].strip
        one_record.save!
      end
    end
  end
end