#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'
require 'csv'
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem "toml", "~> 0.2.0"
end

$terraform_infrastructure_path=ARGV[0] || "../../terraform-infrastructure"
$virgo4_pool_solr_ws_path=ARGV[1] || "../../virgo4-pool-solr-ws"
$environment=ARGV[2] || "staging"

# Read in field.json file
file=File.read($terraform_infrastructure_path+"/virgo4.lib.virginia.edu/ecs-tasks/"+$environment+"/pool-solr-ws/environment/common/fields.json")
fields=JSON.parse(file)['global']['mappings']['definitions']['fields']

# Read in pool json file
def pool(pool_name)
  pool_file=File.read($terraform_infrastructure_path+"/virgo4.lib.virginia.edu/ecs-tasks/"+$environment+"/pool-solr-ws/environment/pools/"+pool_name+".json")
  JSON.parse(pool_file)["local"]["mappings"]["configured"]["field_names"]["detailed"]
end

toml_hash = TOML.load_file($virgo4_pool_solr_ws_path+"/i18n/active.en.toml")
#puts toml_hash['FieldAbbreviatedTitle']['other']

CSV.open("V4-fields.csv","w",
    :write_headers => true,
    :headers => ["Field", "Label", "solr field", "archival", "catalog","hathitrust", "images", "maps", "music-recordings", "musical-scores", "serials", "sound-recordings", "thesis", "uva-library", "video"]
) do |csv|
  fields.each do |field|
    xid = field['xid']
    line =  [field['name'],
             xid ? toml_hash[xid]['other'] : "No Label",
             field['field'],
             pool('archival').include?(field['name']),
             pool('catalog').include?(field['name']),
             pool('hathitrust').include?(field['name']),
             pool('images').include?(field['name']),
             pool('maps').include?(field['name']),
             pool('music-recordings').include?(field['name']),
             pool('musical-scores').include?(field['name']),
             pool('serials').include?(field['name']),
             pool('sound-recordings').include?(field['name']),
             pool('thesis').include?(field['name']),
             pool('uva-library').include?(field['name']),
             pool('video').include?(field['name'])
         ]
    csv << line
  end
  puts("Wrote field summary to V4-fields.csv.")

end