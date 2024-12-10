# frozen_string_literal: true

Item.find_or_create_by(name: 'Flaming Axe', damage: 100,
                       description: 'An axe engulfed in flames, dealing extra fire damage',
                       price: 150, image_url: 'flaming_axe.jpg')
Item.find_or_create_by(name: 'Ice Dagger', damage: 250,
                       description: 'ice_dagger.jpg')
Item.find_or_create_by(name: 'Thunder Hammer', damage: 450,
                       description: 'A hammer that strikes with the power of thunder',
                       price: 200, image_url: 'hammer.jpg')
Item.find_or_create_by(name: 'Poisonous Bow', damage: 100,
                       description: 'A bow that shoots poisoned arrows, weakening enemies over time',
                       price: 130, image_url: 'poison_bow.jpg')
Item.find_or_create_by(name: 'Steel Sword', damage: 80,
                       description: 'A sword forged from high-quality steel, reliable in battle',
                       price: 90, image_url: 'steel_sword.jpg')
Item.find_or_create_by(name: 'Basic Dagger', damage: 20,
                       description: 'A sword forged from high-quality steel, reliable in battle',
                       price: 99_999, image_url: 'dagger.jpg')
