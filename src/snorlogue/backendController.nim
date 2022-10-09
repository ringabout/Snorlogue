import norm/model
import prologue
import std/[strutils, json, strformat, options, sequtils]
import ./constants
import ./service/formService

when defined(postgres):
  import service/postgresService
elif defined(sqlite):
  import service/sqliteService
else:
  {.error: "Snorlogue requires you to specify which database type you use via a defined flag. Please specify either '-d:sqlite' or '-d:postgres'".}

type RequestType = enum
  POST = "post"
  DELETE = "delete"
  PUT = "put"
  PATCH = "patch"
  GET = "get"


proc createHandler[T: Model](ctx: Context, model: typedesc[T], urlPrefix: static string, beforeCreateEvent: EventProc[T], afterCreateEvent: EventProc[T]) {.gcsafe.} =
  {.cast(gcsafe).}:
    var newModel = parseFormData(ctx, T)
    create(newModel, beforeCreateEvent, afterCreateEvent)
  
  let detailPageUrl = fmt"{generateUrlStub(urlPrefix, Page.DETAIL, T)}/{newModel.id}/"
  resp redirect(detailPageUrl)

proc updateHandler[T: Model](ctx: Context, model: typedesc[T], urlPrefix: static string, beforeUpdateEvent: EventProc[T], afterUpdateEvent: EventProc[T]) {.gcsafe.} =
  {.cast(gcsafe).}:
    var updateModel = parseFormData(ctx, T)
    update(updateModel, beforeUpdateEvent, afterUpdateEvent)
  
  let detailPageUrl = fmt"{generateUrlStub(urlPrefix, Page.DETAIL, T)}/{updateModel.id}/"
  resp redirect(detailPageUrl, body = "")

proc deleteHandler[T: Model](ctx: Context, model: typedesc[T], urlPrefix: static string, beforeDeleteEvent: EventProc[T]) {.gcsafe.}=
  let idStr: Option[string] = ctx.getFormParamsOption(ID_PARAM)
  if idStr.isNone():
    resp("", code = Http400)
    return

  let id = parseInt(idStr.get()).int64
  {.cast(gcsafe).}:
    delete(T, id, beforeDeleteEvent)

  let listPageUrl = fmt"{generateUrlStub(urlPrefix, Page.LIST, T)}/"
  resp redirect(listPageUrl)


proc createBackendController*[T: Model](model: typedesc[T], urlPrefix: static string, beforeCreateEvent: EventProc[T], afterCreateEvent: EventProc[T], beforeUpdateEvent: EventProc[T], afterUpdateEvent: EventProc[T], beforeDeleteEvent: EventProc[T]): HandlerAsync =
  result = proc (ctx: Context) {.async, gcsafe.} =
    let requestTypeStr: string = ctx.getFormParams("request-type")
    let requestType: RequestType = parseEnum[RequestType](requestTypeStr)

    case requestType:
    of RequestType.POST: createHandler(ctx, T, urlPrefix, beforeCreateEvent, afterCreateEvent)
    of RequestType.PUT: updateHandler(ctx, T, urlPrefix, beforeUpdateEvent, afterUpdateEvent)
    of RequestType.DELETE: deleteHandler(ctx, T, urlPrefix, beforeDeleteEvent)
    else:
      resp("This endpoint only supports creation, deletion and update of models", code = Http405)
