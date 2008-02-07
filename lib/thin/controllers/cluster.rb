module Thin
  module Controllers
    # Control a set of servers.
    # * Generate start and stop commands and run them.
    # * Inject the port or socket number in the pid and log filenames.
    # Servers are started throught the +thin+ command-line script.
    class Cluster < Controller
      # Number of servers in the cluster.
      attr_accessor :size
        
      # Create a new cluster of servers launched using +options+.
      def initialize(options)
        @options = options.merge(:daemonize => true)
        @size    = @options.delete(:servers)
        @only    = @options.delete(:only)
      
        if socket
          @options.delete(:address)
          @options.delete(:port)
        end
      end
    
      def first_port; @options[:port]       end
      def address;    @options[:address]    end
      def socket;     @options[:socket]     end
      def swiftiply;  @options[:swiftiply]  end
      def pid_file;   @options[:pid]        end
      def log_file;   @options[:log]        end
    
      # Start the servers
      def start
        with_each_server { |port| start_server port }
      end
    
      # Start a single server
      def start_server(number)
        log "Starting server on #{server_id(number)} ... "
      
        run :start, @options, number
      end
  
      # Stop the servers
      def stop
        with_each_server { |n| stop_server n }
      end
    
      # Stop a single server
      def stop_server(number)
        log "Stopping server on #{server_id(number)} ... "
      
        run :stop, @options, number
      end
    
      # Stop and start the servers.
      def restart
        stop
        sleep 0.1 # Let's breath a bit shall we ?
        start
      end
    
      def server_id(number)
        if socket
          socket_for(number)
        elsif swiftiply
          [address, first_port, number].join(':')
        else
          [address, number].join(':')
        end
      end
    
      def log_file_for(number)
        include_server_number log_file, number
      end
    
      def pid_file_for(number)
        include_server_number pid_file, number
      end
    
      def socket_for(number)
        include_server_number socket, number
      end
    
      def pid_for(number)
        File.read(pid_file_for(number)).chomp.to_i
      end
    
      private
        # Send the command to the +thin+ script
        def run(cmd, options, number)
          cmd_options = options.dup
          cmd_options.merge!(:pid => pid_file_for(number), :log => log_file_for(number))
          if socket
            cmd_options.merge!(:socket => socket_for(number))
          elsif swiftiply
            cmd_options.merge!(:port => first_port)
          else
            cmd_options.merge!(:port => number)
          end
          Command.run(cmd, cmd_options)
        end
      
        def with_each_server
          if @only
            yield @only
          else
            @size.times do |n|
              if socket || swiftiply
                yield n
              else
                yield first_port + n
              end
            end
          end
        end
      
        # Add the server port or number in the filename
        # so each instance get its own file
        def include_server_number(path, number)
          ext = File.extname(path)
          path.gsub(/#{ext}$/, ".#{number}#{ext}")
        end
    end
  end
end