# Delegate Python targets to python-pipeline orchestration.
# For Node.js: make -C node-pipeline <target>
%:
	$(MAKE) -C python-pipeline $@

.PHONY: %
