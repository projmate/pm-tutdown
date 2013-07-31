# Basics

:::BEGIN Example

## Example


```html
<div id='main'>
</div>

<div id='sidebar'>
</div>

<script src='js/jquery-1.10.2.min.js'></script>
```

Let's update main DIV

:::< examples/coffee.coffee --block main --no-capture

Let's update sidebar DIV

:::< examples/coffee.coffee --block sidebar --no-capture


:::# Show the script to user
:::< examples/coffee.coffee --as-tab script.coffee --clean

:::# Include the compiled script
:::< ../tmp/examples/coffee.js --hide

:::END
