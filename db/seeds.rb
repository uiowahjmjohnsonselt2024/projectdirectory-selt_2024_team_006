# frozen_string_literal: true

Item.create(name: 'Flaming Axe', damage: 100, description: 'An axe engulfed in flames, dealing extra fire damage',
            price: 150, image_url: 'flaming_axe.jpg')
Item.create(name: 'Ice Dagger', damage: 250,
            description: 'ice_dagger.jpg')
Item.create(name: 'Thunder Hammer', damage: 450, description: 'A hammer that strikes with the power of thunder',
            price: 200, image_url: 'hammer.jpg')
Item.create(name: 'Poisonous Bow', damage: 100,
            description: 'A bow that shoots poisoned arrows, weakening enemies over time',
            price: 130, image_url: 'poison_bow.jpg')
Item.create(name: 'Steel Sword', damage: 80, description: 'A sword forged from high-quality steel, reliable in battle',
            price: 90, image_url: 'steel_sword.jpg')
Item.create(name: 'Basic Dagger', damage: 20,
            description: 'A sword forged from high-quality steel, reliable in battle',
            price: 99_999, image_url: 'dagger.jpg')

Achievement.create(name: "First Kill", description: "Complete your first kill", target: 1, reward: 10)
Achievement.create(name: "First World", description: "Create your first world", target: 1, reward: 10)
Achievement.create(name: "Slayer", description: "Defeat 10 enemies", target: 10, reward: 50)
Achievement.create(name: "Explorer", description: "Explore 10 different worlds", target: 10, reward: 50)
