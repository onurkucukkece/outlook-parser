require 'pry'
require 'launchy'
require 'colorize'
require 'faraday'
require 'open-uri'
require 'json'
require 'base64'

def run
  pry.binding
end

# Get access token
def get_access_token
  url = "https://login.microsoftonline.com/#{ENV['TENANT']}/oauth2/token"

  conn = Faraday.new url: url do |faraday|
    faraday.request  :url_encoded             # form-encode POST params
    faraday.response :logger                  # log requests to STDOUT
    faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
  end

  response = conn.post do |req|
    req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
    req.body = {
      client_id: URI::encode(ENV['CLIENT_ID']),
      client_secret: URI::encode(ENV['CLIENT_SECRET']),
      resource: URI::encode('https://graph.microsoft.com'),
      grant_type: URI::encode('client_credentials'),
    }
  end

  if response.status.to_i == 200
    response_body = JSON.parse(response.body)
    return response_body['access_token']
  else
    return false
  end
end

# Get last 10 mails
def get_mails(token)
  # URL /<email>/messages
  url = "https://graph.microsoft.com/v1.0/users/#{ENV['INBOX']}/messages"
  request = send_request(token, url)

  return request['value'] if request
  return false
end

# Get a specific mail by its id
def get_mail(token, id)
  # URL /<email>/messages/<id>
  url = "https://graph.microsoft.com/v1.0/users/#{ENV['INBOX']}/messages/#{id}"
  request = send_request(token, url)

  return request if request
  return false
end

# Download attachments
def attachments(token, id)
  # URL /<email>/messages/<id>/attachments
  url = "https://graph.microsoft.com/v1.0/users/#{ENV['INBOX']}/messages/#{id}/attachments"
  request = send_request(token, url)

  if request
    files = request['value']
    files.each do |file|
      File.open(file['name'], "wb") do |f|
       f.write(Base64.decode64(file['contentBytes']))
      end
    end
  end
end

def loop_mails(mails)
  mails.each do |mail|
    puts "Subject: #{mail['subject']} | From: | ID: #{mail['id']}"
  end
end

def send_request(token, url, delete=false)
  endpoint = "https://graph.microsoft.com/v1.0/users/#{ENV['INBOX']}#{url}"
  conn = Faraday.new url: endpoint do |faraday|
    faraday.response :logger                  # log requests to STDOUT
    faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
  end

  unless delete
    response = conn.get do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{token}"
    end
  else
    response = conn.delete do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{token}"
    end
  end

  if response.status.to_i == 200
    body = JSON.parse(response.body)
    return body
  else
    return false
  end
end

run
