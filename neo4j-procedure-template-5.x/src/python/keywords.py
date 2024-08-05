import RAKE

# Initialisation de RAKE avec un fichier de mots vides (stopwords)
rake = RAKE.Rake('stopwords.txt')

# Exemple de description de film
description = "Inception est un film de science-fiction qui explore le concept d'invasion et de manipulation des rêves."

# Extraction des mots-clés
keywords = rake.run(description)

# Affichage des mots-clés extraits
print(keywords)
