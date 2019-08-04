CURVE ?= BLS381

.PHONY: test
test: clean
	TEST=SysTests CURVE=$(CURVE) julia --track-allocation=user --compiled-modules=no -e 'import Pkg; Pkg.activate("."); Pkg.build(); Pkg.test(coverage=true)'
	TEST=UnitTests CURVE=$(CURVE) julia --track-allocation=user --compiled-modules=no -e 'import Pkg; Pkg.activate("."); Pkg.build(); Pkg.test(coverage=true)'

.PHONY: bench
bench: clean
	TEST=PerfTests CURVE=$(CURVE) julia --compiled-modules=no -e 'import Pkg; Pkg.activate("."); Pkg.build(); Pkg.test()'

.PHONY: coverage
coverage:
	# julia -e 'using Pkg; Pkg.add("Coverage")' && brew install lcov
	@mkdir -p ./test/coverage
	julia -e 'using Pkg; using Coverage; LCOV.writefile("./test/coverage/lcov.info", process_folder())'
	genhtml -o ./test/coverage ./test/coverage/lcov.info
	open ./test/coverage/index.html

.PHONY: profile
profile:
	julia -e 'import Pkg; Pkg.activate("."); Pkg.test()'

.PHONY: clean
clean:
	@find . -type f -name '*.cov' -delete
	@find . -type f -name '*.mem' -delete
	@rm -rf ./test/coverage
