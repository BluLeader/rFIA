\name{vitalRates}
\alias{vitalRates}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{ Estimate tree growth rates from FIADB}

\description{
Computes estimates of average annual DBH, basal area, height, and net volume growth rates for individual stems, along with average annual basal area and net volume growth per acre. Estimates can be produced for regions defined within the FIA Database (e.g. counties), at the plot level, or within user-defined areal units. Options to group estimates by species, size class, and other variables defined in the FIADB. If multiple reporting years (EVALIDs) are included in the data, estimates will be output as a time series. If multiple states are represented by the data, estimates will be output for the full region (all area combined), unless specified otherwise (e.g. \code{grpBy = STATECD}).}

\usage{
vitalRates(db, grpBy = NULL, polys = NULL, returnSpatial = FALSE, bySpecies = FALSE,
         bySizeClass = FALSE, landType = 'forest', treeType = 'live',
         method = 'TI', lambda = .5, treeDomain = NULL,
         areaDomain = NULL, totals = FALSE, byPlot = FALSE, nCores = 1)
}

\arguments{
  \item{db}{\code{FIA.Database} or \code{Remote.FIA.Database} object produced from \code{\link{readFIA}}. If a \code{Remote.FIA.Database}, data will be read in and processed state-by-state to conserve RAM.}

  \item{grpBy}{variables from PLOT, COND, or TREE tables to group estimates by (NOT quoted). Multiple grouping variables should be combined with \code{c()}, and grouping will occur heirarchically. For example, to produce seperate estimates for each ownership group within ecoregion subsections, specify \code{c('ECOSUBCD', 'OWNGRPCD')}.}

  \item{polys}{\code{sp} or \code{sf} Polygon/MultiPolgyon object; Areal units to bin data for estimation. Seperate estimates will be produces for region encompassed by each areal unit.}

  \item{returnSpatial}{logical; if TRUE, return sf spatial object (polys must also be specified).}

  \item{bySpecies}{logical; if TRUE, returns estimates grouped by species.}

  \item{bySizeClass}{logical; if TRUE, returns estimates grouped by size class (2-inch intervals, see \code{\link{makeClasses}} to compute different size class intervals).}

  \item{landType}{character ('forest' or 'timber'); Type of land which estimates will be produced for. Timberland is a subset of forestland (default) which has high site potential and non-reserve status (see details).}

  \item{treeType}{character ('live' or 'gs'); Type of tree which estimates will be produced for. All (default) includes all stems, live and dead, greater than 1 in. DBH. Live/Dead includes all stems greater than 1 in. DBH which are live or dead (leaning less than 45 degrees), respectively. GS (growing-stock) includes live stems greater than 5 in. DBH which contain at least one 8 ft merchantable log.}

  \item{method}{character; Method used for annual panel combination (see details). One of: 'TI' (temporally indifferent), 'annual' (annual panels), 'SMA' (simple moving average), 'LMA' (linear moving average), or 'EMA' (exponential moving average)}

  \item{lambda}{numeric (0,1); if \code{method == 'EMA'}, the decay parameter used to define weighting scheme for annual panels. Low values place higher weight on more recent panels, and vice versa. Specify a vector of values to compute estimates using mulitple wieghting schemes, and use \code{plotFIA} with \code{grp} set to \code{lambda} to produce moving average ribbon plots.}

  \item{treeDomain}{logical predicates defined in terms of the variables in PLOT, TREE, and/or COND tables. Used to define the type of trees for which estimates will be produced (e.g. DBH greater than 20 inches: \code{DIA > 20}, Dominant/Co-dominant crowns only: \code{CCLCD \%in\% c(2,3))}. Multiple conditions are combined with \code{&} (and) or \code{|} (or). Only trees where the condition evaluates to TRUE are used in producing estimates. Should NOT be quoted.}

  \item{areaDomain}{logical predicates defined in terms of the variables in PLOT and/or COND tables. Used to define the area for which estimates will be produced (e.g. within 1 mile of improved road: \code{RDDISTCD \%in\% c(1:6)}, Hard maple/basswood forest type: \code{FORTYPCD == 805)}. Multiple conditions are combined with \code{&} (and) or \code{|} (or). Only plots within areas where the condition evaluates to TRUE are used in producing estimates. Should NOT be quoted.}

  \item{totals}{logical; if TRUE, return population estimates (e.g. total area, total BA growth) along with ratio estimates (e.g. mean BA growth per acre).}

  \item{byPlot}{logical; if TRUE, returns estimates for individual plot locations (population totals not returned).}

  \item{nCores}{numeric; number of cores to use for parallel implementation. Check available cores using \code{\link{detectCores}}. Default = 1, serial processing.}
}

\details{
Estimation of attributes follows the procedures documented in Bechtold and Patterson (2005). Average annual diameter, basal area, height, and net volume growth of a stem is computed using a sample-based ratio of means estimator of total diameter (basal area, height, net volume) growth / total trees, and average annual basal area and net volume growth per acre is computed as total basal area (net volume) growth / total area. All estimates are returned as average annual rates. Only conditions which were forest in time 1 and in time 2 are included in estimates (excluding converted stands). Only stems 5 inches DBH or greater are included in estimates.

As estimates are of net growth rates, they may attain a negative value. Negative growth estimates most likely indicate a substantial change in an attribute of the tree or area between time 1 and time 2, which caused the attribute to decrease. Implementation of the growth accounting method allows us to more accurately representshifts in forest attributes (biomass) between classified groups (size classes) over time.

Users may specify alternatives to the 'Temporally Indifferent' method for panel combination using the \code{method} argument. Estimators are currently implemented for the temporally indifferent (TI) method (default, used by EVALIDator), simple moving average (SMA), exponential moving average (EMA), and annual estimation (no panel combination). Users may modify the temporal weighting scheme employed by the exponential moving average using the \code{yrs} argument. See Chapter 5 of Bechtold & Patterson (2005) for more details.

Stratified random sampling techniques are most often employed to compute estimates in recent inventories, although double sampling and simple random sampling may be employed for early inventories. Estimates are adjusted for non-response bias by assuming attributes of non-response plot locations to be equal to the mean of other plots included within thier respective stratum or population.

Forest land must be at least 10-percent stocked by trees of any size, including land that formerly had such tree cover and that will be naturally or artificially regenerated. Forest land includes transition zones, such as areas between heavily forested and nonforested lands that are at least 10-percent stocked with trees and forest areas adjacent to urban and builtup lands. The minimum area for classification of forest land is 1 acre and 120 feet wide measured stem-to-stem from the outer-most edge. Unimproved roads and trails, streams, and clearings in forest areas are classified as forest if less than 120 feet wide. Timber land is a subset of forest land that is producing or is capable of producing crops of industrial wood and not withdrawn from timber utilization by statute or administrative regulation. (Note: Areas qualifying as timberland are capable of producing at least 20 cubic feet per acre per year of industrial wood in natural stands. Currently inaccessible and inoperable areas are NOT included).

Easy, efficient parallelization is implemented with the \code{\link{parallel}} package. Users must only specify the \code{nCores} argument with a value greater than 1 in order to implement parallel processing on their machines. Parallel implementation is achieved using a snow type cluster on any Windows OS, and with multicore forking on any Unix OS (Linux, Mac). Implementing parallel processing may substantially decrease free memory during processing, particularly on Windows OS. Thus, users should be cautious when running in parallel, and consider implementing serial processing for this task if computational resources are limited (\code{nCores = 1}).
}

\note{All sampling error estimates are returned as percentages, and represent ~68\% confidence (1 standard deviation). To compute sampling error percent with 95\% confidence, multiply by 1.96.}

\value{
Dataframe or SF object (if \code{returnSpatial = TRUE}). If \code{byPlot = TRUE}, values are returned for each plot. All variables with names ending in \code{SE}, represent the estimate of sampling error (\%) of the variable. All variables with names ending in \code{TOTAL} represent the population total of the variable.

\itemize{
      \item{\strong{YEAR}: reporting year associated with estimates}
      \item{\strong{DIA_GROW}: estimate of mean annual diameter growth of a stem (inches/ yr)}
      \item{\strong{BA_GROW}: estimate of mean annual basal area growth of a stem (sq. ft./ yr)}
      \item{\strong{BAA_GROW}: estimate of mean annual basal area growth per acre (sq. ft./ acre/ yr)}
      %%\item{\strong{HT_GROW}: estimate of mean annual basal area growth of a stem (ft./ yr)}
      \item{\strong{NETVOL_GROW}: estimate of mean annual sound net volume growth of a stem (cu. ft./ yr)}
      \item{\strong{NETVOL_GROW_AC}: estimate of mean annual sound net volume growth per acre (cu. ft./ acre/ yr)}
      \item{\strong{BIO_GROW}: estimate of mean annual aboveground biomass growth of a stem (short tons/ yr)}
      \item{\strong{BIO_GROW_AC}: estimate of mean annual aboveground biomass growth per acre (short tons/ acre/ yr)}
      \item{\strong{nPlots_TREE}: number of non-zero plots used to compute tree and basal area estimates}
      \item{\strong{nPlots_AREA}: number of non-zero plots used to compute land area estimates}
      }
}

\author{
Hunter Stanke and Andrew Finley
}

\references{
FIA Database User Guide: \url{https://www.fia.fs.fed.us/library/database-documentation/}

Bechtold, W.A.; Patterson, P.L., eds. 2005. The Enhanced Forest Inventory and Analysis Program - National Sampling Design and Estimation Procedures. Gen. Tech. Rep. SRS - 80. Asheville, NC: U.S. Department of Agriculture, Forest Service, Southern Research Station. 85 p. \url{https://www.srs.fs.usda.gov/pubs/gtr/gtr_srs080/gtr_srs080.pdf}
}

\seealso{
\code{\link{growMort}}, \code{\link{tpa}}
}

\examples{
## Load data from the rFIA package
data(fiaRI)
data(countiesRI)

## Most recents subset
fiaRI_mr <- clipFIA(fiaRI)


## Most recent estimates for growing-stock on timber land by species
vitalRates(db = fiaRI_mr,
           landType = 'timber',
           treeType = 'gs')
\donttest{

## Estimates for white pine ( > 12" DBH) on forested mesic sites
vitalRates(fiaRI_mr,
           treeType = 'live',
           treeDomain = SPCD == 129 & DIA > 12, # Species code for white pine
           areaDomain = PHYSCLCD \%in\% 21:29) # Mesic Physiographic classes

## Most recent estimates grouped by stand age on forest land
# Make a categorical variable which represents stand age (grouped by 10 yr intervals)
fiaRI_mr$COND$STAND_AGE <- makeClasses(fiaRI_mr$COND$STDAGE, interval = 10)
vitalRates(db = fiaRI_mr,
           grpBy = STAND_AGE)

## Most recent estimates for live stems on forest land by species
vitalRates(db = fiaRI_mr,
           landType = 'forest',
           bySpecies = TRUE)

## Same as above, but implemented in parallel (much quicker)
parallel::detectCores(logical = FALSE) # 4 cores available, we will take 2
vitalRates(db = fiaRI_mr,
           landType = 'forest',
           bySpecies = TRUE,
           nCores = 2)


## Most recent estimates for all stems on forest land grouped by user-defined areal units
ctSF <- vitalRates(fiaRI_mr,
                   polys = countiesRI,
                   returnSpatial = TRUE)
plot(ctSF) # Plot multiple variables simultaneously
plotFIA(ctSF, BIO_GROW) # Plot of individual tree biomass growth rates
}
}


