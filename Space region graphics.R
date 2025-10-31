library(plotrix)

#Draws two graphics of relative distances of Moon, ISS, and Earth

options(scipen = 5)
par(bg = "black")
plot(c(0, 10000), c(-1000, 1000), type = "n", xlab = "", ylab = "", main = "Region of space visited by humans, 1973-Present", yaxt = "n", xaxt = "n", col.main = "white")

draw.circle(x = 0, y = 0, radius = 6371, col = "sky blue")
draw.circle(x = 6371 + 400, y = 0, radius = 40, col = "white")
text(6371 + 450, 100, "ISS",
     cex = .8, col = "white")

plot(c(0, 389000), c(-385000/2, 385000/2), type = "n", xlab = "", ylab = "", main = "Region of space visited by humans, 1969-1972", col = "white", xaxt = "n", col.main = "white")

draw.circle(x = 0, y = 0, radius = 6371, col = "sky blue")
draw.circle(x = 6371 + 384400, y = 0, radius = 3475/2, col = "grey")
text(6371 + 384400, 20000, "Moon",
     cex = .8, col = "white")

