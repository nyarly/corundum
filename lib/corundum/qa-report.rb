module Corundum
  module QA
    #Adopted gratefully from Xavier Shay's Cane
    class ReportFormatter
      def initialize(reports)
        @reports = reports
      end
      attr_reader :reports

      def to_s
        return "" if reports.empty?

        widths = column_widths(reports)

        reports.map do |report|
          report.to_s(widths)
        end.join("\n") + "\n\n" + totals + "\n\n"
      end

      protected

      def max_width(name, &block)
        reports.map(&:rejects).flatten.map do |reject|
          yield(reject).to_s.length
        end.max
      end

      def column_widths(reports)
        Hash[[:file_and_line, :label, :value].map do |name|
          [name, max_width(name, &name)]
        end]
      end

      def totals
        "Total QA report items: #{reports.inject(0){|sum, report| sum + report.length}}"
        "Total QA failing reports: #{reports.inject(0){|sum, report| sum + (report.passed ? 0 : 1)}}"
      end
    end

    class Rejection
      def initialize(label, file, line = nil, value = nil)
        @file, @line, @label, @value = file, line, label, value
      end
      attr_reader :file, :line, :label, :value

      def file_and_line
        @file_and_line ||=
          begin
            if line.nil?
              file
            else
              [file, line].join(":")
            end
          end
      end

      def to_s(column_widths=nil)
        column_widths ||= {}
        [:file_and_line, :label, :value].map do |name|
          if column_widths.has_key?(name)
            self.send(name).to_s.ljust(column_widths[name])
          else
            self.send(name).to_s
          end
        end.join('  ')
      end
    end

    class Report
      def initialize(name)
        @name = name
        @rejects = []
        @passed = true
        @summary = ""
      end
      attr_reader :name, :rejects
      attr_accessor :summary, :passed

      def <<(reject)
        @rejects << reject
      end

      def add(*args)
        self << Rejection.new(*args)
      end

      def fail(summary)
        @passed = false
        @summary = summary
      end

      def length
        @rejects.length
      end
      alias count length

      def empty?
        @rejects.empty?
      end

      def to_s(widths=nil)
        (passed ? "Ok" : "FAIL") +
        ": #{name} (#{length})\n" +
          (summary.empty? ? "" : summary + "\n\n") +
          rejects.map do |reject|
          "  " + reject.to_s(widths)
          end.join("\n")
      end
    end
  end
end
