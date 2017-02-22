target:
	@cat /dev/null > zunit
	@echo "#!/usr/bin/env zsh\n" >> zunit
	@cat src/reports/*.zsh >> zunit
	@cat $(filter-out src/zunit.zsh,$(wildcard src/*.zsh)) >> zunit
	@cat src/commands/*.zsh >> zunit
	@cat src/zunit.zsh >> zunit
	@chmod u+x zunit
	@echo "\033[0;32m✔\033[0;m ZUnit built successfully"

test:
	@./zunit
