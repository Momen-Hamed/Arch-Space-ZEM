quotes=(
    "Have a great day, you deserve it"
    "You are enough, just as you are"
    "Keep going, you got this"
    "Make today count"
    "Stay positive, it pays off"
    "Believe in yourself always"
    "Small steps still move you forward"
    "Be proud of how far you have come"
    "You make a difference"
    "One day at a time"
    "Your effort today builds something great"
    "The best is yet to come"
    "You are stronger than you think"
    "Progress is progress no matter how small"
    "Today is a fresh start, make it yours"
)

index=$(( (10#$(date '+%H') * 2 + 10#$(date '+%M') / 30) % ${#quotes[@]} ))
echo "${quotes[$index]}"
