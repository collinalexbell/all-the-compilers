require "../**"

module Charly::Internals
  # Load a core module or a file
  charly_api "require", TString do |filename|
    begin
      cwd = File.dirname(call.location_start.filename)
      return Require.load(filename.value, cwd, visitor, context)
    rescue e : Require::FileNotFoundException
      raise RunTimeError.new(call.argumentlist.children[0], "Can't load #{filename}")
    end
  end

  # Resolve a filename to a absolute path
  charly_api "require_resolve", TString do |filename|
    cwd = File.dirname(call.location_start.filename)
    path = Require.resolve(filename.value, cwd)
    return TString.new(path)
  end
end
