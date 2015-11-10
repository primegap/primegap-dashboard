module Primegap
  class DashboardApp < Sinatra::Base
    enable :sessions
    register Sinatra::Flash

    use Rack::Auth::Basic, 'Protected Area' do |username, password|
      username == ENV['AUTH_USER'] && password == ENV['AUTH_PSWD']
    end

    get '/' do
      redirect '/apps'
    end

    get '/apps' do
      @apps = $heroku.app.list
      erb :index
    end

    get '/apps/:name' do
      @app = $heroku.app.info(params[:name])
      @dynos = $heroku.dyno.list(params[:name])
      erb :show
    end

    get '/apps/:name/logs', provides: 'text/event-stream' do
      @log_session = $heroku.log_session.create(params[:name], tail: true, lines: 1500)

      stream :keep_open do |out|
        # Keep connection open on cedar
        EventMachine::PeriodicTimer.new(15) { out << "\0" }
        http = EventMachine::HttpRequest.new(@log_session['logplex_url'], keepalive: true, connection_timeout: 0, inactivity_timeout: 0).get

        out.callback do
          out.close
        end
        out.errback do
          out.close
        end

        buffer = ''
        http.stream do |chunk|
          buffer << chunk
          while line = buffer.slice!(/.+\n/)
            begin
              # matches[0] = line
              # matches[1] = timestamp
              # matches[2] = heroku/app
              # matches[3] = process
              # matches[4] = rest

              matches = line.force_encoding('utf-8').match(/(\S+)\s(\w+)\[(\w|.+)\]\:\s(.*)/)
              next if matches.nil? || matches.length < 5

              ps = matches[3].split('.').first
              key_value_pairs = matches[4].split(/(\S+=(?:\"[^\"]*\"|\S+))\s?/)
                                .select { |j| !j.empty? }
                                .map { |j| j.split('=', 2) }

              next unless key_value_pairs.all? { |pair| pair.size == 2 }

              data = Hash[key_value_pairs]
              parsed_line = {}

              if ps == 'router'
                parsed_line = {
                  'dyno'          => data['dyno'],
                  'response_time' => data['service'].to_i,
                  'status'        => "#{data['status']}",
                  'requests'      => 1
                }
                parsed_line['error'] = data['code'] if data['code']
              elsif ps == 'web' && data.key?('sample#memory_total')
                parsed_line = {
                  'dyno'         => data['source'],
                  'memory_total' => data['sample#memory_total'].to_i,
                  'memory_rss'   => data['sample#memory_rss'].to_i,
                  'memory_swap'  => data['sample#memory_swap'].to_i
                }
              elsif ps == 'web' && data.key?('sample#load_avg_1m')
                parsed_line = {
                  'dyno'         => data['source'],
                  'load_avg_1m'  => data['sample#load_avg_1m'].to_f,
                  'load_avg_5m'  => data['sample#load_avg_5m'].to_f,
                  'load_avg_15m' => data['sample#load_avg_15m'].to_f
                }
              end

              unless parsed_line.empty?
                parsed_line['timestamp'] = DateTime.parse(matches[1]).to_time.to_i
                out << "data: #{parsed_line.to_json}\n\n"
              end
            rescue StandardError => e
              puts 'Error caught while parsing logs:'
              puts e.inspect
            end
          end
        end
      end
    end

    post '/dyno/restart' do
      $heroku.dyno.restart(params[:app_name], params[:dyno_name])
      flash[:notice] = "dyno '#{params[:dyno_name]}' has been restarted"
      redirect "/apps/#{params[:app_name]}"
    end
  end
end
