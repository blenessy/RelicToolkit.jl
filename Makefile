.PHONY: test
test: clean
	julia --track-allocation=user -e 'import Pkg; Pkg.activate("."); Pkg.build(); Pkg.test(coverage=true)'

.PHONY: coverage
coverage:
	# julia -e 'using Pkg; Pkg.add("Coverage")' && brew install lcov
	@mkdir -p ./test/coverage
	julia -e 'using Pkg; "Coverage" in keys(Pkg.installed()) || Pkg.add("Coverage"); using Coverage; LCOV.writefile("./test/coverage/lcov.info", process_folder())'
	genhtml -o ./test/coverage ./test/coverage/lcov.info
	open ./test/coverage/index.html

.PHONY: bench
bench:
	julia -e 'import Pkg; Pkg.activate("."); Pkg.test()'

.PHONY: profile
profile:
	julia -e 'import Pkg; Pkg.activate("."); Pkg.test()'

.PHONY: clean
clean:
	@find . -type f -name '*.cov' -delete
	@find . -type f -name '*.mem' -delete
	@rm -rf ./test/coverage
