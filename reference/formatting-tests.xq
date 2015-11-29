xquery version "3.0";

(:collection('/db/apps/twitter/data')/tweet[contains(html, '&amp;')]:)

(:collection('/db/apps/twitter/data')/tweet[ends-with(text, '…')]:)
 
collection('/db/apps/twitter/data')/tweet[ends-with(html, '…')]