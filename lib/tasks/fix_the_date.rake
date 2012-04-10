namespace :fix do
  task :date_problem, [:key] => :environment do |cmd,args|
    desc "Extracts date from message and puts it into appropriate field [with key --fix]"

    # include ActionController::UrlWriter

    if args[:key] == '--fix'
      fix_broken
    else
      show_broken
    end
  end

  # cut date from data and put it into appropriate field
  def fix_broken
    #url = "http://#{`hostname`.strip}:3000"
    url = "http://#{`hostname`.strip}"

    broken_issues = find_broken("Issue")
    broken_comments = find_broken("Journal")

    if broken_issues.blank? && broken_comments.blank? then puts "=== NOTHING TO DO! ==="; return end

    broken_issues.each_with_index do |one_record,ind|
      parsed_data = parse_data one_record.description
      if parsed_data.empty? then puts "something wrong in header format. [issue=#{one_record.id}]"; next end
      pretty_date = parsed_data[:newdate].strftime("%Y-%m-%d %H:%M:%S %z")
      one_record.created_on = parsed_data[:newdate]
      one_record.description = parsed_data[:data]
      begin
        one_record.save
        # puts "#{ind+1} [Issue] " + url + issue_path(one_record) + "\t #{pretty_date}" + "\tFIXED"
        puts "#{ind+1} [Issue] " + url + "/issues/" + one_record.id.to_s + "\t #{pretty_date}" + "\tFIXED"
      rescue => e
        puts "eRRoR"+ e.inspect
      end
    end

    broken_comments.each_with_index do |one_record, ind|
      parsed_data = parse_data one_record.notes
      if parsed_data.empty? then puts "something wrong in header format. [issue=#{one_record.id}]"; next end
      pretty_date = parsed_data[:newdate].strftime("%Y-%m-%d %H:%M:%S %z")
      one_record.created_on = parsed_data[:newdate]
      one_record.notes = parsed_data[:data]
      begin
        one_record.save
        # puts "#{ind+1} [Comment] " + url + issue_path(one_record.journalized_id) + "\t #{pretty_date}" + "\tFIXED"
        puts "#{ind+1} [Comment] " + url + "/issues/" + one_record.journalized_id.to_s + "\t #{pretty_date}" + "\tFIXED"
      rescue => e
        puts "eRRoR"+ e.inspect
      end
    end
    puts "=== DONE! ==="
  end

  # just show broken records
  def show_broken
    url = "http://#{`hostname`.strip}:3000"

    broken_issues = find_broken("Issue")
    broken_comments = find_broken("Journal")

    if broken_issues.blank? && broken_comments.blank? then puts "=== NOTHING TO DO! ==="; return end

    broken_issues.each_with_index do |one_record,ind|
      parsed_data = parse_data one_record.description
      if parsed_data.empty? then puts "something wrong in header format. [issue=#{one_record.id}]"; next end
      pretty_date = parsed_data[:newdate].strftime("%Y-%m-%d %H:%M:%S %z")
      # puts "#{ind+1} [Issue] " + url + issue_path(one_record) + "\t #{pretty_date}" # + "\t #{parsed_data[:data]}"
      puts "#{ind+1} [Issue] " + url + "/issues/" + one_record.id.to_s + "\t #{pretty_date}" # + "\t #{parsed_data[:data]}"
    end

    broken_comments.each_with_index do |one_record, ind|
      parsed_data = parse_data one_record.notes
      if parsed_data.empty? then puts "something wrong in header format. [issue=#{one_record.id}]"; next end
      pretty_date = parsed_data[:newdate].strftime("%Y-%m-%d %H:%M:%S %z")
      # puts "#{ind+1} [Comment] " + url + issue_path(one_record.journalized_id) + "\t #{pretty_date}" # + "\t #{parsed_data[:data]}"
      puts "#{ind+1} [Comment] " + url + "/issues/" + one_record.journalized_id.to_s + "\t #{pretty_date}" # + "\t #{parsed_data[:data]}"
    end
    puts "=== DONE! ==="
  end

  # find all records where the date entered into the data field
  def find_broken model
    date_pattern = 'Date'
    case model
      when "Issue"
        broken_elements = Issue.find(:all, :conditions=> ["description like ?", date_pattern + "%"])
      when "Journal"
        broken_elements = Journal.find(:all, :conditions=> ["notes like ?", date_pattern + "%"])
      else
        return nil
    end
  end

  # extract date and real data from data field
  def parse_data elem_data
    time_regexp = /^Date: (\w\w\w \w\w\w \d\d \d\d:\d\d:\d\d (\+|\-)\d\d\d\d \d\d\d\d)(.*)$/m
    date_format = "%a %b %d %H:%M:%S %z %Y"

    matches = time_regexp.match elem_data
    result = Hash.new

    if matches && matches.captures.count == 3
      olddate =  matches.captures[0]
      data = matches.captures[2].strip
      begin
        newdate = DateTime.strptime(olddate, date_format)
        result[:newdate] = newdate
        result[:data] = data
      rescue => e
        puts e.inspect + "INVALID DATA: \n #{elem_data}"
      end
    end

    return result
  end
end
