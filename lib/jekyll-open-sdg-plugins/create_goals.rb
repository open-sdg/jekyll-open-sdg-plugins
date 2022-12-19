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

      goal_heading = ''
      goal_content = ''
      goal_content_heading = ''
      if site.config['create_goals'].has_key?('goal_content_heading')
        goal_content_heading = site.config['create_goals']['goal_content_heading']
      end
      if site.config['create_goals'].has_key?('goals')
        # Try to find goal content by match the goal ID with a "goal" property on each item
        # in the create_goals.goals site config. Otherwise fallback to the order they appear
        # in that list.
        goal_by_goal = site.config['create_goals']['goals'].detect {|g| g['goal'].to_s == goal.to_s }
        goal_by_index = site.config['create_goals']['goals'][goal_index]
        if !goal_by_goal.nil?
          goal_content = goal_by_goal['content']
          if goal_by_goal.has_key?('content_heading') && goal_by_goal['content_heading'] != ''
            goal_content_heading = goal_by_goal['content_heading']
          end
          if goal_by_goal.has_key?('heading')
            goal_heading = goal_by_goal['heading']
          end
        elsif !goal_by_index.nil?
          if !goal_by_index.has_key?('goal') || goal_by_index['goal'].to_s == goal.to_s
            goal_content = goal_by_index['content']
            if goal_by_index.has_key?('content_heading') && goal_by_index['content_heading'] != ''
              goal_content_heading = goal_by_index['content_heading']
            end
            if goal_by_index.has_key?('heading')
              goal_heading = goal_by_index['heading']
            end
          end
        end
      end
      @content = goal_content

      self.process(@name)
      self.data = {}
      self.data['goal_number'] = goal.to_s
      self.data['language'] = language
      self.data['layout'] = layout
      self.data['goal_content_heading'] = goal_content_heading
      self.data['goal_heading'] = goal_heading
    end
  end
end
