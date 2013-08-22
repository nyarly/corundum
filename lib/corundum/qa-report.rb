module Corundum
  module QA
    #Adopted gratefully from Xavier Shay's Cane
    class ReportFormatter
      def initialize(reports)
        @reports = reports
      end

      def to_s
        return "" if reports.empty?

        widths = column_widths(reports, columns)

        reports.map do |report|
          report.to_s(widths)
        end.join("\n") + "\n\n" + totals + "\n\n"

        string
      end

      protected

      def column_widths(reports, columns)
        {
          :file_and_line => reports.map {|reject| reject.file_and_line.to_s.length }.max,
          :label => reports.map {|reject| reject.label.to_s.length }.max,
          :value => reports.map {|reject| reject.value.to_s.length }.max
        }
      end

      def totals
        "Total QA Rejections: #{reports.inject(0){|sum, length| sum + length}}"
      end
    end

    class Rejection
      def initialize(label, file, line = nil, value = nil)
        @file, @line, @label, @value = test, file, line, label, value
      end
      attr_reader :file, :line, :label, :value

      def file_and_line
        @file_and_line ||=
          begin
            if line.nil?
              file
            else
              "%s:%i" % file, line
            end
          end
      end

      def to_s(column_widths=nil)
        column_widths ||= {}
        [
          file_and_line.to_s.ljust(column_widths[:file_and_line]),
          label.to_s.ljust(column_widths[:label]),
          value.to_s.ljust(column_widths[:value])
        ].join('  ')
      end
    end

    class Report
      def initialize(name)
        @name = name
        @rejects = []
        @passed = true
        @summary = ""
      end
      attr_reader :rejects
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

      def to_s(widths)
        passed ? "Ok" : "FAIL"
        ": #{name} (#{length})\n" +
          summary.empty? ? "" : summary + "\n\n"
          rejects.map do |reject|
          "  " + reject.to_s(widths)
          end.join("\n")
      end
    end
  end
end
