# Future event dragon families

These five concept families are deliberately stored outside Flutter's
`assets/` tree. They therefore do not increase the current app download and
cannot appear in gameplay before an event is designed and approved.

Each family contains six independent 1024px WebP sprites with real alpha and
safe transparent padding. Every head and body axis points toward screen-right.
The fixed review order is Hatchling, Wyrmling, Might, Arcana, Spirit and
Mastery.

| Event idea | Family | Visual identity |
| --- | --- | --- |
| Halloween | Gloamgourd | Charcoal harvest dragon with pumpkin light, vine horns, witchfire and guardian wisps |
| Christmas | Hollyfrost | White-and-evergreen winter dragon with golden antlers, holly, frost crystal and lantern light |
| New Year's Day | Dawnchime | Indigo-and-dawn dragon with chimes, firework fins, turning-year rings and sunrise ribbons |
| Valentine's Day | Rosevow | Rose-quartz vow dragon with petal wings, thorn-gold armor and a warm heart gem |
| Pridefest | Spectrumplume | Pearl-and-prism festival dragon with an inclusive full-spectrum feather mantle and aurora ribbons |

Run `dart run tool/build_event_dragon_family_reviews.dart` to create saturated
blue 3-by-2 review sheets under `build/event_dragon_family_reviews/`. The blue
background makes matte remnants, transparent holes, cropping and direction
errors easy to spot without shipping the review files in the app or repository.

None of these concepts currently defines a schedule, egg, chest, reward,
rarity or drop chance. When one becomes a real Special Adventure, use the
DragonHaven Special Adventure skill and update the living event and randomness
references as applicable.
