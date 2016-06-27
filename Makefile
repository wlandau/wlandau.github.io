md = $(wildcard _source/*.md)
html = $(patsubst _source/%.md,_includes/%.html,$(md))

all: $(html)

_includes/%.html: _source/%.md
	pandoc $< -o $@

clean:
	rm $(html)
