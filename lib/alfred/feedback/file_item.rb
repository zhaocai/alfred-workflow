require "rexml/document"
require "alfred/feedback/item"

module Alfred
  class Feedback
    class FileItem < Item

      def initialize(path)
        if ['.ennote', '.webbookmark'].include? File.extname(path)
          @title = %x{mdls -name kMDItemDisplayName -raw '#{path}'}
        else
          @title = File.basename(path)
        end
        @subtitle = path
        @uid = path
        @arg = path
        @icon = {:type => "fileicon", :name => path}
        @valid = 'yes'
        @autocomplete = @title
        @type = 'file'
      end

      def match?(query)
        return true if query.empty?
        if query.is_a? String
          query = query.split("\s")
        end

        queries = []
        query.each { |q|
          queries << smart_query(q)
        }

        queries.delete_if { |q|
          q.match(@title) or q.match(@subtitle)
        }

        if queries.empty?
          return true
        else
          return false
        end
      end

    end
  end
end
