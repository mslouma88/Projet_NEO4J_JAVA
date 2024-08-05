import io
from google.cloud import vision

# Initialiser le client Google Cloud Vision
client = vision.ImageAnnotatorClient()

# Charger l'image d'une affiche
with io.open('path_to_your_movie_poster.jpg', 'rb') as image_file:
    content = image_file.read()
    image = vision.Image(content=content)

# Envoyer l'image à l'API et recevoir les étiquettes
response = client.label_detection(image=image)
labels = response.label_annotations

# Afficher les résultats
for label in labels:
    print(f"{label.description}: {label.score * 100:.2f}%")
