# pm-tutdown

Projmate filter to create tutorials and documentation from literate markdown.

## Directives

### Example Section - `:::BEGIN Example` ... `:::END`

Markdown between these markers are treated as live examples.

### Code Block Modifiers - `:::@ OPTIONS`

This directive is used to set arguments for next code block with these options

Name | Description
------------------
--hide | Capture the code block as an asset but do not display in rendered HTML.
--no-capture | Display the next code block but do not capture as an asset.


### Include Block, File - `:::< FILENAME OPTIONS`

Use this directive to include a `{{{ Content` ... `}}}` section from a file. Given this file

    function Foo() {

    //{{{ Content main
      console.log("Hello world!");
    //}}}

    }

### Including an Entire File as-is

    :::< foo.js --raw

### Including File as Source, removing any `{{{ Content` and `}}}`

    :::< foo.js --clean

### Including Blocks

This directive


    :::< foo.js --block main --no-capture

results in

    ```@ --no-capture

    ```js
      console.log("Hello world!");
    ```

### Including File as Tab


    :::< examples/game.coffee --as-tab game.coffee
