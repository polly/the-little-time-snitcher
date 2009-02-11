Shoes.setup do
  gem 'tmail'
end

require "tmail"
require "net/smtp"

module TLTS
  module Utils
   class Mailer
     class << self
       def send_message(args)
         construct_mail args
         send           args[:auth]
       end
   
       private
   
       def construct_mail(args)
         from, to, subject, body = args[:from], args[:to], args[:subject], args[:body]
         
         @mail =  TMail::Mail.parse("From: #{from}\nTo: #{to}\nSubject: #{subject}\nDate: #{Time.now}\n\n#{body}")
       end
   
       def send(args)
         smtp, port, domain, username, password, type = args[:smtp], args[:port], args[:domain], args[:username], args[:password], args[:type]
         Thread.new do
           Net::SMTP.start(smtp, port, domain, username, password, type) do |smtp|
             smtp.send_message @mail.to_s, @mail.from, @mail.to
           end
         end
       end
     end
   end

    class Timer

      def start
        @counter = 0
      end
  
      def stop
        @counter = 0
      end

      def seconds
        @counter % 60
      end
  
      def minutes
        @counter / 60 % 60 
      end

      def hours
        @counter / (60 * 60)
      end

      def time(format="%02d:%02d:%02d")
        increment_counter
        format_time_output format
      end

      def increment_counter(count=1)
        @counter += count
      end
  
  
      private

      def format_time_output(format) 
        format % [
          hours,
          minutes,
          seconds
        ]
      end
    end
  end

  module UI
    def text_field(args)
      generic_field "edit_line", args
    end

    def text_area(args)
      generic_field "edit_box", args
    end

    private

    def generic_field(field_type, args)
      margin, width, title = args[:margin], args[:width], args[:title]

      stack :margin => margin, :width => width do
        para title
      end

      stack :margin => margin, :width => "-#{width}" do
        @text = eval(field_type)
      end

      return @text
    end
  end
end



class Application < Shoes 
  include TLTS::UI
  
  url '/',      :index
  url '/timer', :timer

  def index
    background "#333".."#999"
    
    stack :margin => 10 do 
      title "New Report"
    end
    
    @@company     = text_field :margin => 10, :width => "85px", :title => "Company:     "
    @@project     = text_field :margin => 10, :width => "85px", :title => "Project:     "
    @@description = text_area  :margin => 10, :width => "90px", :title => "Description: "
    
    button "Save" do 
      visit "/timer" 
    end
  end

  def timer
    background "#333".."#999"
    @timer = TLTS::Utils::Timer.new

    @display = stack :margin => 10, :height => "100px" do
      @label = title "00:00:00"
    end
    
    flow :margin => 10 do
      @start_button = button "Start" do
        start_timer
        hide_start_button
      end
      
      button "Stop" do
        stop_timer
        send_mail
        visit "/"
      end
    end
    

    def start_timer
      @timer.start
      display_time
    end

    def stop_timer
      @timer.stop
      @animation.stop
    end
    
    def hide_start_button
      @start_button.hide
    end

    def display_time
      @animation = animate(1) do
        @display.clear do
          @current_time = @timer.time
          title @current_time
        end
      end
    end
    
    def send_mail
      body = <<-END
      Timereport: #{@@company.text}
      
        Duration: #{@current_time}
        Project : #{@@project.text}
        
        Description: 
      
        #{@@description.text}
      END
      
      TLTS::Utils::Mailer.send_message(
        :from    => "Donald Duck <donald@disneyland.com>",
        :to      => "Mickey Mouse <mickey@disneyland.com>",
        :subject => "Timereport: #{@@company.text}",
        :body    => body,
        :auth    => {
          :smtp     => "smtp.domain.com",
          :port     => 25,
          :domain   => "domain.com",
          :username => "donald@disneyland.com",
          :password => "unlucky",
          :type     => :login
        }
      )
    end
  end
end

Shoes.app :width => 400, :height => 400, :title => "The Little Time Snitch"
