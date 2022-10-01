import std/[tables, strformat, strutils]
import norm/model
import prologue
import backendController
import frontendController
import constants
import pageContexts
import nimja/parser

# proc addAdminRoutes*[T: Model](app: Prologue, route: string, models: TableRef[string, typedesc[T]], middlewares: seq[HandlerAsync] = @[] ) =
#   ## Adds create, read, update and delete routes for every provided model.
#   ## Also adds an overview-route over all models, which will show them split into sections as per the provided model table.
#   ## All routes will have the middlewares provided in the `middlewares` param attached to them.
#   app.addModelOverviewRoute(route, models, middlewares)
#
#   for sectionHeading, sectionModels in models.mpairs:
#       for model in sectionModels:
#         app.addCrudRoutes(route, model, middlewares)
const ID_PATTERN* = fmt r"(?P<{ID_PARAM}>[\d]+)"
const PAGE_PATTERN* =  fmt r"(?P<{PAGE_PARAM}>[\d]+)"

var REGISTERED_MODELS*: seq[string] = @[]


proc validateModel[T: Model](model: typedesc[T]) =
  ## Ensure the following: 
  ## 1) Model is not read only
  ## 2) Model has no other model fields, they should be only FK fields
  discard

proc addCrudRoutes*[T: Model](app: var Prologue, modelType: typedesc[T], middlewares: seq[HandlerAsync] = @[]) =
  validateModel[T](modelType)
  REGISTERED_MODELS.add($T)
  
  let baseRoute = ($T).toLower()

  app.addRoute(
    re fmt"/{baseRoute}/{$Page.DETAIL}/{ID_PATTERN}/",
    handler = createDetailController[T](T),
    httpMethod = HttpGet,
    middlewares = middlewares
  )

  app.addRoute(
    re fmt"/{baseRoute}/{$Page.LIST}/{PAGE_PATTERN}/",
    handler = createListController(T),
    httpMethod = HttpGet,
    middlewares = middlewares
  )

  app.addRoute(
    re fmt"/{baseRoute}/{$Page.LIST}/",
    handler = createListController(T),
    httpMethod = HttpGet,
    middlewares = middlewares
  )

  app.addRoute(
    re fmt"/{baseRoute}/{$Page.DELETE}/{ID_PATTERN}/",
    handler = createConfirmDeleteController(T),
    httpMethod = HttpGet,
    middlewares = middlewares
  )

  app.addRoute(
    re fmt"/{baseRoute}/{$Page.CREATE}/",
    handler = createCreateFormController(T),
    httpMethod = HttpGet,
    middlewares = middlewares
  )

  app.addRoute(
    re fmt"/{baseRoute}/",
    handler = createCreateController(T),
    httpMethod = HttpPost,
    middlewares = middlewares,
  )

  app.addRoute(
    re fmt"/{baseRoute}/{ID_PATTERN}/",
    handler = createDeleteController(T),
    httpMethod = HttpDelete,
    middlewares = middlewares
  )

  app.addRoute(
    re fmt"/{baseRoute}/{ID_PATTERN}/",
    handler = createUpdateController(T),
    httpMethod = HttpPut,
    middlewares = middlewares
  )

proc addAdminRoutes*(app: var Prologue, middlewares: seq[HandlerAsync] = @[]) =
  app.addRoute(
    re fmt"/{$Page.OVERVIEW}/",
    handler = createOverviewController(REGISTERED_MODELS),
    httpMethod = HttpGet,
    middlewares = middlewares
  )