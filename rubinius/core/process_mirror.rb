module Rubinius
  class Mirror
    module Process
      def self.set_status_global(status)
        ::Thread.current[:$?] = status
      end

      def self.fork
        Rubinius.primitive :vm_fork
        raise PrimitiveFailure, "Rubinius::Mirror::Process.fork primitive failed"
      end

      def self.exec(*args)
        exe = Execute.new(*args)
        exe.spawn_setup
        exe.exec exe.command, exe.argv
      end

      def self.spawn(*args)
        exe = Execute.new(*args)

        begin
          pid = exe.spawn exe.options, exe.command, exe.argv
        rescue SystemCallError => error
          set_status_global ::Process::Status.new(pid, 127)
          raise error
        end

        pid
      end

      def self.backtick(str)
        Rubinius.primitive :vm_backtick
        raise PrimitiveFailure, "Rubinius::Mirror::Process.backtick primitive failed"
      end

      class Execute
        attr_reader :command
        attr_reader :argv
        attr_reader :options

        # Turns the various varargs incantations supported by Process.spawn into a
        # [env, prog, argv, redirects, options] tuple.
        #
        # The following method signature is supported:
        #   Process.spawn([env], command, ..., [options])
        #
        # The env and options hashes are optional. The command may be a variable
        # number of strings or an Array full of strings that make up the new process's
        # argv.
        #
        # Assigns @environment, @command, @argv, @redirects, @options. All
        # elements are guaranteed to be non-nil. When no env or options are
        # given, empty hashes are returned.
        def initialize(env_or_cmd, *args)
          if options = Rubinius::Type.try_convert(args.last, ::Hash, :to_hash)
            args.pop
          end

          if env = Rubinius::Type.try_convert(env_or_cmd, ::Hash, :to_hash)
            unless command = args.shift
              raise ArgumentError, "command argument expected"
            end
          else
            command = env_or_cmd
          end

          if args.empty? and
              cmd = Rubinius::Type.try_convert(command, ::String, :to_str)
            raise Errno::ENOENT if cmd.empty?

            @command = cmd
            @argv = []
          else
            if cmd = Rubinius::Type.try_convert(command, ::Array, :to_ary)
              raise ArgumentError, "wrong first argument" unless cmd.size == 2
              command = StringValue(cmd[0])
              name = StringValue(cmd[1])
            else
              name = command = StringValue(command)
            end

            argv = [name]
            args.each { |arg| argv << StringValue(arg) }

            @command = command
            @argv = argv
          end

          @options = Rubinius::LookupTable.new if options or env

          if options
            options.each do |key, value|
              case key
              when ::IO, ::Fixnum, :in, :out, :err
                from = convert_io_fd key
                to = convert_to_fd value, from
                redirect @options, from, to
              when ::Array
                from = convert_io_fd key.first
                to = convert_to_fd value, from
                key.each { |k| redirect @options, convert_io_fd(k), to }
              when :unsetenv_others
                if value
                  array = @options[:env] = []
                  ENV.each_key { |k| array << convert_env_key(k) << nil }
                end
              when :pgroup
                if value == true
                  value = 0
                elsif value
                  value = Rubinius::Type.coerce_to value, ::Integer, :to_int
                  raise ArgumentError, "negative process group ID : #{value}" if value < 0
                end
                @options[key] = value
              when :chdir
                @options[key] = Rubinius::Type.coerce_to_path(value)
              when :umask
                @options[key] = value
              when :close_others
                @options[key] = value if value
              else
                raise ArgumentError, "unknown exec option: #{key.inspect}"
              end
            end
          end

          if env
            array = (@options[:env] ||= [])

            env.each do |key, value|
              array << convert_env_key(key) << convert_env_value(value)
            end
          end
        end

        private :initialize

        def redirect(options, from, to)
          case to
          when ::Fixnum
            map = (options[:redirect_fd] ||= [])
            map << from << to
          when ::Array
            map = (options[:assign_fd] ||= [])
            map << from
            map.concat to
          end
        end

        def convert_io_fd(obj)
          case obj
          when ::Fixnum
            obj
          when :in
            0
          when :out
            1
          when :err
            2
          when ::IO
            obj.fileno
          else
            raise ArgementError, "wrong exec option: #{obj.inspect}"
          end
        end

        def convert_to_fd(obj, target)
          case obj
          when ::Fixnum
            obj
          when :in
            0
          when :out
            1
          when :err
            2
          when :close
            nil
          when ::IO
            obj.fileno
          when ::String
            [obj, default_mode(target), 0644]
          when ::Array
            case obj.size
            when 1
              [obj[0], File::RDONLY, 0644]
            when 2
              if obj[0] == :child
                convert_to_fd obj[1], target
              else
                [obj[0], convert_file_mode(obj[1]), 0644]
              end
            when 3
              [obj[0], convert_file_mode(obj[1]), obj[2]]
            end
          else
            raise ArgumentError, "wrong exec redirect: #{obj.inspect}"
          end
        end

        def default_mode(target)
          if target == 1 or target == 2
            OFLAGS["w"]
          else
            OFLAGS["r"]
          end
        end

        def convert_file_mode(obj)
          case obj
          when ::Fixnum
            obj
          when ::String
            OFLAGS[obj]
          when nil
            OFLAG["r"]
          else
            Rubinius::Type.coerce_to obj, Integer, :to_int
          end
        end

        def convert_env_key(key)
          key = Rubinius::Type.check_null_safe(StringValue(key))

          if key.include?("=")
            raise ArgumentError, "environment name contains a equal : #{key}"
          end

          key
        end

        def convert_env_value(value)
          return if value.nil?
          Rubinius::Type.check_null_safe(StringValue(value))
        end

        def spawn_setup
          Rubinius.invoke_primitive :vm_spawn_setup, @options
        end

        def spawn(exe, command, args)
          Rubinius.primitive :vm_spawn
          raise PrimitiveFailure,
            "Rubinius::Mirror::Process::Execute#spawn primitive failed"
        end

        def exec(command, args)
          Rubinius.primitive :vm_exec
          raise PrimitiveFailure,
            "Rubinius::Mirror::Process::Execute#exec primitive failed"
        end
      end
    end
  end
end
