class Fetch
  def self.get(url)
    response = Crest::Request.new(:get, url, json: true).execute
    raise "Could not fetch: #{url} - http status code was: #{response.status_code}" unless response.status_code == 200
    response.body
  end
end
