require "jekyll"
require_relative "helpers"

module JekyllOpenSdgPlugins
  class CreateGoals < Jekyll::Generator
    safe true
    priority :normal

    def generate(site)
      # If site.create_goals is set, create goals per the metadata.
      if site.config['languages'] and site.config['create_goals']
        # Compile the list of goals.
        goals = {}
        metadata = {}
        default_language = site.config['languages'][0]
        metadata = site.data[default_language]['meta']
        metadata.each do |inid, indicator|
          if indicator.has_key?('standalone') and indicator['standalone']
            next
          end
          goal = inid.split('-')[0]
          goals[goal] = true
        end
        # Decide what layout to use for the goal pages.
        layout = 'goal'
        # See if we need to "map" any language codes.
        languages_public = Hash.new
        if site.config['languages_public']
          languages_public = opensdg_languages_public(site)
        end
        # Loop through the languages.
        site.config['languages'].each_with_index do |language, index|
          # Get the "public language" (for URLs) which may be different.
          language_public = language
          if languages_public[language]
            language_public = languages_public[language]
          end
          # Loop through the goals.
          goal_index = 0
          # In the SDGs the goals are numeric, so try to sort them numerically.
          begin
            goals_sorted = goals.keys.sort_by { |k| k.to_i if Float(k) rescue k }
          rescue
            goals_sorted = goals.keys.sort
          end
          goals_sorted.each do |goal|
            # Add the language subfolder for all except the default (first) language.
            dir = index == 0 ? goal.to_s : File.join(language_public, goal.to_s)
            # Create the goal page.
            site.collections['goals'].docs << GoalPage.new(site, site.source, dir, goal, language, layout, goal_index)
            goal_index += 1
          end
        end
      end
    end
  end

  # A Page subclass used in the `CreateGoals` class.
  class GoalPage < Jekyll::Page
    def initialize(site, base, dir, goal, language, layout, goal_index)
      @site = site
      @base = base
      @dir  = dir
      @name = 'index.html'

      goal_content = ''
      if site.config['create_goals'].has_key?('goals')
        # Try to find goal content by match the goal ID with a "goal" property on each item
        # in the create_goals.goals site config. Otherwise fallback to the order they appear
        # in that list.
        matching_goal = site.config['create_goals']['goals'].detect {|g| g['goal'] == goal.to_s }
        if matching_goal.nil? && !site.config['create_goals']['goals'][goal_index].nil?
          goal_content = site.config['create_goals']['goals'][goal_index]['content']
        elsif !site.config['create_goals']['goals'][goal_index].nil?
          goal_content = matching_goal['content']
        end
      end
      @content = goal_content

      self.process(@name)
      self.data = {}
      self.data['goal_number'] = goal.to_s
      self.data['language'] = language
      self.data['layout'] = layout
    end
  end
end
