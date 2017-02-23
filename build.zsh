#!/usr/bin/env zsh

# Clear the file to start with
cat /dev/null > zunit

# Start with the shebang
echo "#!/usr/bin/env zsh\n" >> zunit

# We need to do some fancy globbing
setopt EXTENDED_GLOB

# Print each of the source files into the target, removing any comments
# and blank lines from the compiled executable
cat src/**/(^zunit).zsh | grep -v -E '^(\s*#.*[^"]|\s*)$' >> zunit

# Print the main command last
cat src/zunit.zsh | grep -v -E '^(\s*#.*[^"]|\s*)$' >> zunit

# Make sure the file is executable
chmod u+x zunit

# Let the user know we're finished
echo "\033[0;32m✔\033[0;m ZUnit built successfully"
