# encoding: UTF-8

require 'json'
require 'i18n'
require './extend_string'
require 'ruby-progressbar'
require 'unicode'

# todo: remove periods, etc.
# todo: account for "up'"

def convertToCharCodes(str)
  codes = []
  str.each_char do |c|
    codes.push c.unpack("U*")
  end
  return codes.join('-')
end

def convertFromCharCodes(str)
  codes = str.split('-').map { |code| code.to_i }
  codes.pack('U*')
end

mounce_dictionary = JSON.parse(File.read("../greek/mounce_dictionary/json/main.json"))

totalMorphs = Dir.glob("../morphs/json/*/*/**.json").length
progressbar = ProgressBar.create(:title => "Processing morphs", :starting_at => 0, :total => totalMorphs)

Dir.glob("../morphs/json/*/*/**.json").each do |file|
  parts = file.split('/')
  reference = parts[3] + parts[4] + parts[5].split('.')[0]

  File.open(file, "r") do |file|
    words = JSON.load file
    words.each do |word|
      lemma = Unicode::normalize_C(word[5])
      lemmaCodes = convertToCharCodes(lemma)
      firstCharacterCode = lemmaCodes.split('-')[0]
      path = "json/" + firstCharacterCode

      if(!File.directory?("json/" + firstCharacterCode))
        Dir::mkdir("json/" + firstCharacterCode)
      end

      data = {}
      if File.exist?(path + "/" + lemmaCodes + ".json")
        File.open(path + "/" + lemmaCodes + ".json", "r") do |test1|
          if !test1
            next
          end
          data = JSON.load(test1)
        end
      end

      if !data['forms']
        data['forms'] = {}
      end

      if !data['occurences']
        data['occurences'] = 1
      else
        data['occurences'] = data['occurences'] + 1
      end

      if !data['forms'][word[0] + word[1]]
        data['forms'][word[0] + word[1]] = []
      end
      if data['forms'][word[0] + word[1]].length < 100
        data['forms'][word[0] + word[1]].push([reference,word[4]])
      end

      if !data['definitions'] and mounce_dictionary[lemma]
        data['definitions'] = {}
      end

      if mounce_dictionary[lemma] and !data['definitions']['mounce']
        data['definitions']['mounce'] = mounce_dictionary[lemma]['definition']
      end

      File.open(path + "/" + lemmaCodes + ".json","w") do |fileToWrite|
        fileToWrite.write(JSON.pretty_generate(data))
      end
    end
  end

  progressbar.increment
end