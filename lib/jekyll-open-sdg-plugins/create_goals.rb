require "jekyll"

module JekyllOpenSdgPlugins
  class CreateGoals < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      # If site.create_goals is set, create goals per the metadata.
      if site.config['languages'] and site.config['create_goals']
        # Compile the list of goals.
        goals = {}
        site.data['meta'].each do |inid, meta|
          goal = inid.split('-')[0].to_i
          goals[goal] = true
        end
        # Decide what layout to use for the goal pages.
        layout = 'goal'
        if site.config['create_goals'].key?('layout')
          layout = site.config['create_goals']['layout']
        end
        # Loop through the languages.
        site.config['languages'].each_with_index do |language, index|
          # Loop through the goals.
          goals.sort.each do |goal, value|
            # Add the language subfolder for all except the default (first) language.
            dir = index == 0 ? goal.to_s : File.join(language, goal.to_s)
            # Create the goal page.
            site.collections['goals'].docs << GoalPage.new(site, site.source, dir, goal, language, layout)
          end
        end
      end
    end
  end

  # A Page subclass used in the `CreateGoals` class.
  class GoalPage < Jekyll::Page
    def initialize(site, base, dir, goal, language, layout)
      @site = site
      @base = base
      @dir  = dir
      @name = 'index.html'

      self.process(@name)
      self.data = {}
      self.data['sdg_goal'] = goal.to_s
      self.data['language'] = language
      self.data['layout'] = layout
    end
  end
end
