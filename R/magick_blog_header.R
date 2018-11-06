# Make a blog post header image by downloading freely available image files
# and pasting them together with magick.

library(magick)
library(glue)

docker <- image_read("https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Docker_%28container_engine%29_logo.svg/610px-Docker_%28container_engine%29_logo.svg.png") %>%
  image_crop("260x145")

github <- image_read("https://assets-cdn.github.com/images/modules/logos_page/Octocat.png") %>%
  image_scale("260x145")

digital_ocean <- image_read("https://upload.wikimedia.org/wikipedia/commons/f/ff/DigitalOcean_logo.svg") %>%
  image_scale("x180")

clouds <- image_read("https://upload.wikimedia.org/wikipedia/commons/thumb/f/fb/Cute_cartoon_clouds_with_stars.svg/800px-Cute_cartoon_clouds_with_stars.svg.png")

clouds_height <- image_info(clouds)$height

# The easiest way to make a composite image is to start with a blank canvas and 
# overlay images on it using image_composite(operator = "Over").
# offset is number of pixels (x,y) from the top-left corner
canvas <- magick::image_blank(width = 800,
                              height = 220,
                              col = "white")

image_composite(canvas, github, operator = "Over", offset = "+20+40") %>%
  image_composite(docker, operator = "Over", offset = "+250+10") %>%
  image_composite(digital_ocean, operator = "Over", offset = "+555+0") %>%
  image_composite(clouds, 
                  operator = "Over", 
                  offset = glue("+0+{220-clouds_height}")) %>%
  image_write(path = "public/img/headers/how-to-run-an-r-analysis-anywhere.png", format = "png")
