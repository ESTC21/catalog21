# catalog21

Catalog21 is a modified fork of the ARC Collex project found at https://github.com/collex/catalog.  It includes expanded crowdsourcing functionalities and an expanded metadata RDF schema to handle a wider range of library specific data.

Catalog21 is part of an extended suite of software that runs the estc21 <beta available at estc21.ucr.edu> and that includes four primary components:

* estc21_solr:  a Solr/Lucene instance that provides the datastore for the application.
* estc21_rdf_indexer:  A Java application that parses MARC data and exports records as RDF.
* Catalog21:  A Rails application that provides an API to the SOLR index.
* Collex21:  A Rails web application that provides user functionality to interact with the ESTC21.  Collex21 is the web gateway to the ESTC21.

The below diagram depicts the interaction between these various packages:

![ESTC21 Ecosystem Overview](http://ds.lib.ucdavis.edu/estc21/estc21_ecosystem_overview.png)

For more information on the application, see relevant Wiki pages.
