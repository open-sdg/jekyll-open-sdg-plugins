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
        # Are we using translated builds?
        translated_builds = site.config['translated_builds']
        metadata = {}
        if translated_builds
          # If we are using translated builds, the 'meta' data is underneath
          # language codes. We just use the first language.
          default_language = site.config['languages'][0]
          metadata = site.data[default_language]['meta']
        else
          # Otherwise the 'meta' data is not underneath any language code.
          metadata = site.data['meta']
        end
        metadata.each do |inid, indicator|
          goal = inid.split('-')[0].to_i
          goals[goal] = true
        end
        # Decide what layout to use for the goal pages.
        layout = 'goal'
        if site.config['create_goals'].key?('layout')
          layout = site.config['create_goals']['layout']
        end
        # See if we need to "map" any language codes.
        languages_public = Hash.new
        if site.config['languages_public']
          languages_public = site.config['languages_public']
        end
        # Loop through the languages.
        site.config['languages'].each_with_index do |language, index|
          # Get the "public language" (for URLs) which may be different.
          language_public = language
          if languages_public[language]
            language_public = languages_public[language]
          end
          # Loop through the goals.
          goals.sort.each do |goal, value|
            # Add the language subfolder for all except the default (first) language.
            dir = index == 0 ? goal.to_s : File.join(language_public, goal.to_s)
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
      self.data['goal_number'] = goal.to_s
      self.data['language'] = language
      self.data['layout'] = layout
      # Backwards compatibility:
      self.data['sdg_goal'] = self.data['goal_number']
    end
  end
end
