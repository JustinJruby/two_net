require 'builder'
require 'httparty'

module TwoNet

class Client

  include HTTParty
  headers  'Content-Type' => 'application/xml' ,'Accept' => 'application/xml'
  debug_output if ENV['TWONET_DEBUG']
  base_uri( ENV['TWONET_URL'])
  @key = ENV['TWONET_KEY']
  @secret = ENV['TWONET_SECRET']
  basic_auth(@key, @secret)
  @error = nil;
     #timezone = 'Canada/Atlantic' Or "Atlantic Time (Canada)"

  def self.get_error()
  	return @error;
  end   
  def self.clear_error()
  	@error = nil
  end
  def self.register_user(guid)
    response = Client.post('/partner/register', :body=>{:guid=>guid }.to_xml(:root=>:registerRequest))
    return false if @error = response["errorStatus"].blank? == false
    return  response["trackGuidsResponse"]["status"]["code"] == "1"
  end

  def self.delete_user(guid)
    response = Client.delete("/partner/user/delete/#{guid}")
    return false if @error = response["errorStatus"].blank? == false
    return check_status_response response
  end

   def self.user_exists?(guid)
    response = Client.get("/partner/user/exists/#{guid}")
    return check_status_response response
  end

  #return array
  def self.get_guids()
    audit_response = Client.get('/partner/audit/guids')
    return nil if audit_response["auditResponse"]["status"]["code"] != "1"
    return audit_response["auditResponse"]["guids"]["guid"]
  end

 def self.user_track_details(guid)
    response = Client.get("/partner/user/tracks/details/#{guid}")
    return check_user_track_details_response response
  end

## TODO clean up the hash that arrives back
  def self.list_all_sensors(guid)
    response = TwoNet.get("/partner/user/tracks/registerable/#{guid}")
    response["trackRegistrationTemplateResponse"]
  end


  #Properties
    # [ {:name=>:make, :value=> make },
    #    {:name=>:model, :value=>model},
    #    {:name=>:serialNumber, :value=>identification},
    #   {:name=>:qualifier, :value=>1}
    # ]
 #

  def self.add_sensor(guid,properties)
    # https://twonetcom.qualcomm.com/kernel/api/objects/trackRegistrationRequest.jsp 
    body = {:guid=>guid ,
            :type =>"2net",
            :properties => properties,
            "registerType" => "properties" }
    response = Client.post('/partner/user/track/register',:body=>Client.trackRegistrationRequest_xml(body))
    return false if @error = response["errorStatus"].blank? == false
    return nil if response["trackRegistrationResponse"]["status"]["code"].to_s != "1"
    return response["trackRegistrationResponse"]["trackDetail"]["guid"]
  end

  def self.add_oauth(opts={})
    guid = opts[:type]
    type = opts[:type]
    body = {:guid=>guid,
            :type =>type,
            "registerType" => "oauth" }
    response = Client.post('/partner/user/track/register',:body=>body.to_xml(:root=>'trackRegistrationRequest'))
    return false if @error = response["errorStatus"].blank? == false
    return nil if response["trackRegistrationResponse"]["status"]["code"].to_s != "1"
    return response["trackRegistrationResponse"]["oauthAuthorizationUrl"]
  end

  def self.remove_sensor(guid,track_id)
    response = Client.delete("/partner/user/track/unregister/#{guid}/#{track_id}")
    return Client.check_status_response response
  end

  def self.generate_guid()
    SecureRandom.uuid
  end
  def self.latest_reading(opts={})
    guid = opts[:guid]
    track_guid = opts[:track_guid]
     #timezone = 'Canada/Atlantic'
    body = Client.trackRequest_xml(guid: guid, track_guid: track_guid)
    response = Client.post('/partner/user/track/latest',:body=>body)
  end

  def self.latest_activity(opts={})
    guid = opts[:guid]
    track_guid = opts[:track_guid]
    timezone = opts[:timezone]
     #timezone = 'Canada/Atlantic'
    body = activityRequest_xml(guid: guid,  track_guid: track_guid, timezone: timezone)
    response = Client.post('/partner/activity/day/latest',:body=>body)
  end

  def self.filtered_activity(opts={})
    guid = opts[:guid]
    track_guid = opts[:track_guid]
    timezone = opts[:timezone]
    start_date = opts[:start_date]
    end_date = opts[:end_date]

    body = Client.activityRequestFilter_xml(guid: guid, track_guid: track_guid, 
                            start_date: start_date.to_i, end_date: end_date.to_i, 
                              timezone: timezone )
    response = Client.post('/partner/activity/filtered',:body=>body)
  end

  def self.latest_blood(opts={})
    guid = opts[:guid]
    track_guid = opts[:track_guid]

    body = measureRequest_xml(guid: guid, track_guid: track_guid)
    response = Client.post('/partner/measure/blood/latest',:body=>body)
    return nil if @error = response["measureResponse"]["status"]["code"].to_s != "1"
    return response["measureResponse"]
  end

  def self.latest_breath(opts={})
    guid = opts[:guid]
    track_guid = opts[:track_guid]

    body = measureRequest_xml(guid: guid, track_guid: track_guid)
    response = Client.post('/partner/measure/breath/latest',:body=>body)
    return nil if response["measureResponse"]["status"]["code"].to_s != "1"
    return response["measureResponse"]
  end

  def self.latest_body(opts={})
    guid = opts[:guid]
    track_guid = opts[:track_guid]
    timezone = opts[:timezone]

    body = Client.measureRequest_xml(guid: guid, track_guid: track_guid, timezone: timezone)
    response = Client.post('/partner/measure/body/latest',:body=>body)
    return nil if @error = response["measureResponse"]["status"]["code"] != "1"
    return response["measureResponse"]
  end

# measurement in blood, breath, blood
  def self.user_latest(opts={})
    measurement = opts[:measurement]
    patient_guid = opts[:patient_guid]
    sensor_guid = opts[:sensor_guid]
    timezone = opts[:timezone]

    if measurement == :blood
      results = Client.latest_blood(guid: patient_guid,track_guid: sensor_guid)
    elsif measurement == :body
      results = Client.latest_body(guid: patient_guid,track_guid: sensor_guid, timezone: timezone)
    elsif measurement == :breath
      results = Client.latest_breath(guid: patient_guid,track_guid: sensor_guid)
    end
  return results
  end

 def self.user_latest_debug(opts={})
    measurement = opts[:measurement]
    patient_guid = opts[:patient_guid]
    sensor_guid = opts[:sensor_guid]
    timezone = opts[:timezone]
    results = Hash.new
    
      results["blood"] = Client.latest_blood(guid: patient_guid,track_guid: sensor_guid)
    
      results["body"] = Client.latest_body(guid: patient_guid,track_guid: sensor_guid, timezone: timezone)
    
      results["breath"] = Client.latest_breath(guid: patient_guid,track_guid: sensor_guid)
    
  return results
  end

  def self.user_filtered(opts={})
    measurement = opts[:measurement]
    guid = opts[:guid]
    track_guid = opts[:track_guid]
    start_date = opts[:start_date]
    end_date = opts[:end_date]
    timezone = opts[:timezone]

    body = Client.measureRequest_xml(guid: guid,  track_guid: track_guid, timezone: timezone, start_date: start_date,  end_date: end_date)
    if measurement == "blood"
      response = Client.post('/partner/measure/blood/filtered', :body=>body)
    elsif measurement == "body"
      response = Client.post('/partner/measure/body/filtered', :body=>body)
    elsif measurement == "breath"
      response = Client.post('/partner/measure/breath/filtered',:body=>body)
    elsif measurement == "activity"
	 response = Client.post('/partner/measure/activity/filtered',:body=>body)
    end

    return nil if response["measureResponse"]["status"]["code"] != "1"
    return response["measureResponse"]
  end

  def self.debug_user_filtered(opts={})
    measurement = opts[:measurement]
    guid = opts[:guid]
    track_guid = opts[:track_guid]
    start_date = opts[:start_date]
    end_date = opts[:end_date]
    timezone = opts[:timezone]
	responses = Hash.new
    
    body = Client.measureRequest_xml(guid: guid,  track_guid: track_guid, timezone: timezone, start_date: start_date,  end_date: end_date)
    
      responses["blood"] = Client.post('/partner/measure/blood/filtered', :body=>body)
    
      responses["body"] = Client.post('/partner/measure/body/filtered', :body=>body)
    
      responses["breath"] = Client.post('/partner/measure/breath/filtered',:body=>body)
  
   

    return  responses
  end



  def self.check_status_response(response)
    return false if @error = response["errorStatus"].blank? == false
    return response["statusResponse"]["status"]["code"].to_s == "1"
  end

  def self.check_response(object, response, data)
    return false if @error = response["errorStatus"].blank? == false ||  response[object].nil?
    return nil if response[object]["status"]["code"].to_s != "1"
    return response[object][data]
  end

 def self.check_user_track_details_response(response)
    return false if @error = response["errorStatus"].blank? == false
    return nil if response["trackDetailsResponse"]["status"]["code"].to_s != "1"
    return response["trackDetailsResponse"]["trackDetails"]
  end

  def self.trackRegistrationRequest_xml(body)
    builder = Builder::XmlMarkup.new
    xml = builder.trackRegistrationRequest do |xml|
      xml.guid body[:guid]
      xml.type body[:type]
      xml.registerType body[:registerType]
      xml.properties do
        body[:properties].each do |property|
          xml.property do
            xml.name property[:name].to_s
            xml.value property[:value]
          end
        end
      end
    end
    xml
  end

  def self.activityRequest_xml(opts={})
    guid = opts[:guid]
    track_guid = opts[:track_guid]
    timezone = opts[:timezone]
    builder = Builder::XmlMarkup.new
    xml = builder.activityRequest do |xml|
      xml.guid guid
      xml.trackGuid track_guid
      xml.timezone timezone
    end
    xml
  end

  def self.measureRequest_xml(opts={})
    guid = opts[:guid]
    track_guid = opts[:track_guid]
    timezone = opts[:timezone]
    start_date = opts[:start_date]
    end_date = opts[:end_date]


    builder = Builder::XmlMarkup.new
    xml = builder.measureRequest do |xml|
      xml.guid guid
      xml.trackGuid track_guid
      xml.filter do |xml2|
        xml2.startDate start_date.to_i
        xml2.endDate end_date.to_i
        xml2.aggregateLevel 'EPOCH'
    end
      xml.timezone timezone
    end
    xml
  end

  def self.trackRequest_xml(opts={})
    guid = opts[:guid]
    track_guid = opts[:track_guid]
    start_date = opts[:start_date]
    end_date = opts[:end_date]

    builder = Builder::XmlMarkup.new
    xml = builder.trackRequest  do |xml|
      xml.guid guid
      xml.trackGuid track_guid
      xml.filter do |xml2|
        xml2.startDate start_date.to_i
        xml2.endDate end_date.to_i
        xml2.aggregateLevel 'EPOCH'
      end
    end
    xml
  end

  def self.activityRequestFilter_xml(opts={})
    guid = opts[:guid]
    track_guid = opts[:track_guid]
    start_date = opts[:start_date]
    end_date = opts[:end_date]
    timezone = opts[:timezone]

    builder = Builder::XmlMarkup.new
    xml = builder.activityRequest  do |xml|
      xml.guid guid
      xml.trackGuid track_guid
      xml.filter do |xml2|
        xml2.startDate start_date.to_i
        xml2.endDate end_date.to_i
        xml2.aggregateLevel 'EPOCH'
    end
      xml.timezone timezone
    end
    xml
  end

  def self.arrayify(object)
    object.is_a?(Array) ? object : [object]
  end


  def fake_glucometer
   properties = [ {:name=>:make, :value=>'Entra'},
     {:name=>:model, :value=>'MGH-BT1'},
      {:name=>:serialNumber, :value=>'2NET00001'},
      {:name=>:qualifier, :value=>1}
      ]
    return properties
  end

  def fake_pulse_oximeter
   properties = [ {:name=>:make, :value=>'Nonin'},
     {:name=>:model, :value=>'9560 Onyx II'},
      {:name=>:serialNumber, :value=>'2NET00002'},
      {:name=>:qualifier, :value=>1}
      ]
    return properties
  end

  def fake_weigh_scale
   properties = [ {:name=>:make, :value=>'A&D'},
     {:name=>:model, :value=>'UC-321PBT'},
      {:name=>:serialNumber, :value=>'2NET00003'},
      {:name=>:qualifier, :value=>1}
      ]
    return properties
  end

  def fake_blood_pressure
   properties = [ {:name=>:make, :value=>'A&D'},
     {:name=>:model, :value=>'UA-767PBT'},
      {:name=>:serialNumber, :value=>'2NET00004'},
      {:name=>:qualifier, :value=>1}
      ]
    return properties
  end
  def fake_inhaler
   properties = [ {:name=>:make, :value=>'Asthmapolis'},
     {:name=>:model, :value=>'Rev B'},
      {:name=>:serialNumber, :value=>'2NET00005'},
      {:name=>:qualifier, :value=>1}
      ]
    return properties
  end
  def add_fake_sensors(guid, properties)
    # https://twonetcom.qualcomm.com/kernel/api/objects/trackRegistrationRequest.jsp 
    body = {:guid=>guid ,
            :type =>"2net",
            :properties => properties,
            "registerType" => "properties" }
    response = Client.post('/partner/user/track/register',:body=>TwoNet.trackRegistrationRequest_xml(body))
    return false if response["errorStatus"].blank? == false
    return nil if response["trackRegistrationResponse"]["status"]["code"].to_s != "1"
    return response["trackRegistrationResponse"]["trackDetail"]["guid"]
  end

  def compress_track(track_details)
    h = Hash.new
   # return nil if track_details.nil? == true

    track_detail = track_details["trackDetail"]
    return [] if track_detail.blank?
    track_detail = Client.arrayify(track_detail)
    track_detail.each do |track_detail|
      h[ track_detail["guid"] ] = track_detail["properties"]
    end
    return h
  end

  def print_uid_sensors(guids = nil)
    guids = Client.get_guids() if guids == nil
   	guids= Client.arrayify(guids)
    h = Hash.new
    guids.each do |guid|
     results =  Client.user_track_details(guid)
      h[guid] =  compress_track(results)
    end
    return h
  end
end
end
