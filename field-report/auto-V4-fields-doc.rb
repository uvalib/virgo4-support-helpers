#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'
require 'csv'
require 'toml'

$fields_path=ARGV[0]
$pools_path=ARGV[1]
$active_toml_path=ARGV[2]

# Read in field.json file
file=File.read($fields_path+"fields.json")
fields=JSON.parse(file)['global']['mappings']['definitions']['fields']

# Read in pool json file
def pool(pool_name)
  pool_file=File.read($pools_path+pool_name+".json")
  JSON.parse(pool_file)["local"]["mappings"]["configured"]["field_names"]["detailed"]
end

toml_hash = TOML.load_file($active_toml_path+"active.en.toml")
#puts toml_hash['FieldAbbreviatedTitle']['other']

CSV.open("V4-fields.csv","w",
    :write_headers => true,
    :headers => ["Field", "Label", "solr field", "archival", "catalog","hathitrust", "images", "maps", "music-recordings", "music-scores", "serials", "sound-recordings", "thesis", "uva-library", "video"]
) do |csv|
  (0 ..fields.count).each do |i|
    xid = fields[i]['xid']
    line =  [fields[i]['name'],
             xid ? toml_hash[xid]['other'] : "No Label",
             fields[i]['field'],
             pool('archival').include?(fields[i]['name']),
             pool('catalog').include?(fields[i]['name']),
             pool('hathitrust').include?(fields[i]['name']),
             pool('images').include?(fields[i]['name']),
             pool('maps').include?(fields[i]['name']),
             pool('music-recordings').include?(fields[i]['name']),
             pool('music-scores').include?(fields[i]['name']),
             pool('serials').include?(fields[i]['name']),
             pool('sound-recordings').include?(fields[i]['name']),
             pool('thesis').include?(fields[i]['name']),
             pool('uva-library').include?(fields[i]['name']),
             pool('video').include?(fields[i]['name'])
         ]
    csv << line
  end

end
