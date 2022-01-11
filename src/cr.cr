#!/usr/bin/env crystal
# coding: utf-8
#  ---------------------------------------------------
#  File          : cr.crystal
#  Authors       : ccmywish <ccmywish@qq.com>
#  Created on    : <2022-1-11>
#  Last modified : <2022-1-11>
#
#  This file is used to explain a CRyptic command
#  or an acronym's real meaning in computer world or
#  orther fileds.
#
#  ---------------------------------------------------

require "toml"

CRYPTIC_RESOLVER_HOME = File.expand_path("~/.cryptic-resolver", home: Path.home)
CRYPTIC_DEFAULT_SHEETS = {
  computer: "https://github.com/cryptic-resolver/cryptic_computer.git",
  common:   "https://github.com/cryptic-resolver/cryptic_common.git",
  science:  "https://github.com/cryptic-resolver/cryptic_science.git",
  economy:  "https://github.com/cryptic-resolver/cryptic_economy.git",
  medicine: "https://github.com/cryptic-resolver/cryptic_medicine.git"
}

CRYPTIC_VERSION = "1.0.0"


####################
# helper: for color
####################

def bold(str)       "\e[1m#{str}\e[0m" end
def underline(str)  "\e[4m#{str}\e[0m" end
def red(str)        "\e[31m#{str}\e[0m" end
def green(str)      "\e[32m#{str}\e[0m" end
def yellow(str)     "\e[33m#{str}\e[0m" end
def blue(str)       "\e[34m#{str}\e[0m" end
def purple(str)     "\e[35m#{str}\e[0m" end
def cyan(str)       "\e[36m#{str}\e[0m" end


####################
# core: logic
####################

def is_there_any_sheet?
  unless Dir.exists? CRYPTIC_RESOLVER_HOME
    Dir.mkdir CRYPTIC_RESOLVER_HOME
  end

  !Dir.empty? CRYPTIC_RESOLVER_HOME
end


def add_default_sheet_if_none_exist
  unless is_there_any_sheet?
    puts "cr: Adding default sheets..."
    CRYPTIC_DEFAULT_SHEETS.values.each do |sheet|
      `git -C #{CRYPTIC_RESOLVER_HOME} clone #{sheet} -q`
    end
    puts "cr: Add done"
  end
end


def update_sheets(sheet_repo)
  add_default_sheet_if_none_exist

  if sheet_repo.nil?
    puts "cr: Updating all sheets..."

    Dir.children(CRYPTIC_RESOLVER_HOME).each do |sheet|
      puts "cr: Wait to update #{sheet}..."
      `git -C #{CRYPTIC_RESOLVER_HOME}/#{sheet} pull -q`
    end

    puts "cr: Update done"
  else
    `git -C #{CRYPTIC_RESOLVER_HOME} clone #{sheet_repo} -q`
    puts "cr: Add new sheet done"
  end
end


def load_dictionary(path,file)
  file = CRYPTIC_RESOLVER_HOME + "/#{path}/#{file}.toml"

  if File.exists? file
    str = File.read(file)
    return TOML.parse(str)
  else
    return nil
  end
end


# Pretty print the info of the given word
#
# A info looks like this
#   emacs = {
#     disp = "Emacs"
#     desc = "edit macros"
#     full = "a feature-rich editor"
#     see  = ["Vim"]
#   }
#
# @param info [Hash] the information of the given word (mapped to a keyword in TOML)
def pp_info(info : Hash)
  disp = info["disp"] || red("No name!")
  puts "\n  #{disp}: #{info["desc"]}"

  if full = info["full"]
    print "\n  ",full,"\n"
  end

  if see_also = info["see"].as(Array)
    print "\n", purple("SEE ALSO ")
    see_also.each {|x| print underline(x),' '}
    puts
  end
  puts
end

# Print default cryptic_ sheets
def pp_sheet(sheet)
    puts green("From: #{sheet}")
end


# Used for synonym jump
# Because we absolutely jump to a must-have word
# So we can directly lookup to it
#
# Notice that, we must jump to a specific word definition
# So in the toml file, you must specify the precise word.
# If it has multiple meanings, for example
#
#   [blah]
#   same = "XDG"  # this is wrong
#
#   [blah]
#   same = "XDG.Download" # this is right
def directly_lookup(sheet,file,word)
  dict = load_dictionary(sheet,file.downcase)

  return false if dict.nil? # make the Crystal compiler happy

  words =  word.split('.') # [XDG Download]
  word = words.shift # XDG [Download]
  explain = words.first
  if explain.nil?
    info = dict[word].as(Hash)
  else
    info = dict[word].as(Hash).[explain].as(Hash)
  end

  # Warn user this is the toml maintainer's fault
  if info.nil?
    puts red("WARN: Synonym jumps to a wrong place at `#{word}`
      Please consider fixing this in `#{file.downcase}.toml` of the sheet `#{sheet}`")
    exit
  end

  pp_info(info)
  return true # always true
end


# Lookup the given word in a dictionary (a toml file in a sheet) and also print.
# The core idea is that:
#
# 1. if the word is `same` with another synonym, it will directly jump to
#   a word in this sheet, but maybe a different dictionary
#
# 2. load the toml file and check whether it has the only one meaning.
#   2.1 If yes, then just print it using `pp_info`
#   2.2 If not, then collect all the meanings of the word, and use `pp_info`
#
def lookup(sheet, file, word)
  # Only one meaning
  dict = load_dictionary(sheet,file)
  return false if dict.nil?

  # We firstly want keys in toml be case-insenstive, but later in 2021/10/26 I found it caused problems.
  # So I decide to add a new must-have format member: `disp`
  # This will display the word in its traditional form.
  # Then, all the keywords can be downcase.

  info = dict[word].as(Hash) # Directly hash it
  return false if info.nil?

  # Warn user if the info is empty. For example:
  #   emacs = { }
  if info.size == 0
    puts red("WARN: Lack of everything of the given word
      Please consider fixing this in the sheet `#{sheet}`")
    exit
  end

  # Check whether it's a synonym for anther word
  # If yes, we should lookup into this sheet again, but maybe with a different file
  if same = info["same"].as(String)
    pp_sheet(sheet)
    # point out to user, this is a jump
    puts blue(bold(word)) + " redirects to " + blue(bold(same))

    if same[0].downcase == file  # no need to load dictionary again
      # Explicitly convert it to downcase.
      # In case the dictionary maintainer redirects to an uppercase word by mistake.
      same = same.downcase
      sameinfo = dict[same].as(Hash)
      if info.nil?
        puts red("WARN: Synonym jumps to the wrong place `#{same}`,
          Please consider fixing this in `#{file.downcase}.toml` of the sheet `#{sheet}`")
        exit
        return false
      else
        pp_info(sameinfo)
        return true
      end
    else
      return directly_lookup(sheet, same[0], same)
    end
  end

  # Check if it's only one meaning
  if info.has_key?("desc")
    pp_sheet(sheet)
    pp_info(info)
    return true
  end

  # Multiple meanings in one sheet
  info_keys = info.keys

  unless info_keys.empty?
    pp_sheet(sheet)
    info_keys.each do |meaning|
      pp_info(dict[word].as(Hash)[meaning].as(Hash))
      # last meaning doesn't show this separate line
      print  blue(bold("OR")),"\n" unless info_keys.last == meaning
    end
    return true
  else
    return false
  end
end


# The main logic of `cr`
#   1. Search the default's first sheet first
#   2. Search the rest sheets in the cryptic sheets default dir
#
# The `search` procedure is done via the `lookup` function. It
# will print the info while finding. If `lookup` always return
# false then means lacking of this word in our sheets.So a wel-
# comed contribution is prinetd on the screen.
def solve_word(word)

  add_default_sheet_if_none_exist

  word = word.downcase # downcase! would lead to frozen error in Ruby 2.7.2
  # The index is the toml file we'll look into
  index = word[0]
  case index
  when '0'..'9'
    index = "0123456789"
  end

  # Default's first should be 1st to consider
  first_sheet = "cryptic_" + CRYPTIC_DEFAULT_SHEETS.keys[0].to_s # When Ruby3, We can use SHEETS.key(0)

  # cache lookup results
  results = [] of Bool
  results << lookup(first_sheet,index,word)
  # return if result == true # We should consider all sheets

  # Then else
  rest = Dir.children(CRYPTIC_RESOLVER_HOME)
  rest.delete first_sheet
  rest.each do |sheet|
    results << lookup(sheet,index,word)
    # continue if result == false # We should consider all sheets
  end

  unless results.includes? true
    puts <<-NotFound
cr: Not found anything.

You may use `cr -u` to update the sheets.
Or you could contribute to our sheets: Thanks!

  1. computer:   #{CRYPTIC_DEFAULT_SHEETS[:computer]}
  2. common:     #{CRYPTIC_DEFAULT_SHEETS[:common]}
  3. science:    #{CRYPTIC_DEFAULT_SHEETS[:science]}
  4. economy:    #{CRYPTIC_DEFAULT_SHEETS[:economy]}
  5. medicine:   #{CRYPTIC_DEFAULT_SHEETS[:medicine]}


NotFound
# This must be a bug in Crystal, the above two lines should be cut by one
  else
    return
  end

end


def help
  puts <<-HELP
cr: Cryptic Resolver version #{CRYPTIC_VERSION} in Crystal

usage:
  cr -h                     => print this help
  cr -u (xx.com//repo.git)  => update default sheet or add sheet from a git repo
  cr emacs                  => Edit macros: a feature-rich editor
HELP
end



####################
# main: CLI Handling
####################

if ARGV.size > 1
  arg = ARGV.shift
else
  arg = ""
end

case arg
when ""            then (help || add_default_sheet_if_none_exist)
when "-h"           then help
when "-u"           then update_sheets   ARGV.shift
else
  solve_word arg
end
