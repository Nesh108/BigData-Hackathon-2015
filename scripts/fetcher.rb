# -*- coding: utf-8 -*-

# Author: Nesh108
# Date: 26/09/2015

require 'net/http'
require 'uri'
require 'addressable/uri'
require 'json'

business_data = Hash.new
companies = Array.new(1000)

# Fetching the page
source_uri = URI('http://avoindata.prh.fi:80/tr/v1?totalResults=false&maxResults=1000&resultsFrom=0&companyRegistrationFrom=2000-02-28')
resp = Net::HTTP.get_response(source_uri)
results = JSON.parse(resp.body)

results['results'].each do |business|
    resp = Net::HTTP.get_response(URI(business['detailsUri']))
    results = JSON.parse(resp.body)

    results['results'].each do |business_detail|

      begin
        business_data["businessId"] = business_detail["businessId"]
        business_data["name"] = business_detail["name"]
        business_data["street"] = business_detail["addresses"][0]["street"]
        business_data["postCode"] = business_detail["addresses"][0]["postCode"]
        business_data["city"] = business_detail["addresses"][0]["city"]
        business_data["country"] = business_detail["addresses"][0]["country"]
        business_data["registrationDate"] = business_detail["addresses"][0]["registrationDate"]

        typeURI = URI("http://avoindata.prh.fi:80/bis/v1?totalResults=false&maxResults=1&resultsFrom=0&businessId=" + business_detail["businessId"] + "&companyRegistrationFrom=2000-02-28")
        type_res = JSON.parse(Net::HTTP.get_response(typeURI).body)

        if(type_res["results"][0]["businessLines"].any?) then
          if(!type_res["results"][0]["businessLines"][0]["code"].nil?)
            business_data["type_code"] = type_res["results"][0]["businessLines"][0]["code"]
          else
            business_data["type_code"] = ""
          end
        else
          business_data["type_code"] = ""
        end


        if(!business_detail["addresses"][0]["website"].nil?) then
          business_data["website"] = business_detail["addresses"][0]["website"]
        else
          business_data["website"] = ""
        end

        if(!business_detail["addresses"][0]["phone"].nil?) then
          business_data["phone"] = business_detail["addresses"][0]["phone"]
        else
          business_data["phone"] = ""
        end

        if(!business_detail["addresses"][0]["fax"].nil?) then
          business_data["fax"] = business_detail["addresses"][0]["fax"]
        else
          business_data["fax"] = ""
        end

        geolocation = Addressable::URI.parse("https://maps.google.com/maps/api/geocode/json?address=" + business_data["street"].gsub(" ", "%20") + "," + business_data["city"] + "," + business_data["country"] + "&sensor=false")

        rep = Net::HTTP.get_response(geolocation)
        res = JSON.parse(rep.body)

        business_data["lat"] = res["results"][0]["geometry"]["location"]["lat"]
        business_data["lng"] = res["results"][0]["geometry"]["location"]["lng"]
        puts business_data.to_json + ","
      rescue Exception=>e
        puts "#"
      end
    end
end
