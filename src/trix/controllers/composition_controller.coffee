#= require trix/controllers/attachment_editor_controller
#= require trix/views/document_view

{handleEvent, tagName, benchmark, findClosestElementFromNode}  = Trix

{attachmentSelector} = Trix.AttachmentView

class Trix.CompositionController extends Trix.BasicObject
  constructor: (@element, @composition) ->
    @documentView = new Trix.DocumentView @composition.document, {@element}

    handleEvent "focus", onElement: @element, withCallback: @didFocus
    handleEvent "click", onElement: @element, matchingSelector: "a[contenteditable=false]", preventDefault: true
    handleEvent "mousedown", onElement: @element, matchingSelector: attachmentSelector, withCallback: @didClickAttachment
    handleEvent "click", onElement: @element, matchingSelector: "a#{attachmentSelector}", preventDefault: true

  didFocus: =>
    @delegate?.compositionControllerDidFocus?()

  didClickAttachment: (event, target) =>
    attachment = @findAttachmentForElement(target)
    @delegate?.compositionControllerDidSelectAttachment?(attachment)

  render: benchmark "CompositionController#render", ->
    unless @revision is @composition.revision
      @documentView.setDocument(@composition.document)
      @documentView.render()
      @revision = @composition.revision

    unless @documentView.isSynced()
      @delegate?.compositionControllerWillSyncDocumentView?()
      @documentView.sync()
      @reinstallAttachmentEditor()
      @delegate?.compositionControllerDidSyncDocumentView?()

    @delegate?.compositionControllerDidRender?()

  rerenderViewForObject: (object) ->
    @documentView.invalidateViewForObject(object)
    @render()

  focus: ->
    @documentView.focus()

  isViewCachingEnabled: ->
    @documentView.isViewCachingEnabled()

  enableViewCaching: ->
    @documentView.enableViewCaching()

  disableViewCaching: ->
    @documentView.disableViewCaching()

  refreshViewCache: ->
    @documentView.garbageCollectCachedViews()

  # Attachment editor management

  installAttachmentEditorForAttachment: (attachment) ->
    return if @attachmentEditor?.attachment is attachment
    return unless element = @documentView.findElementForObject(attachment)
    @uninstallAttachmentEditor()
    attachmentPiece = @composition.document.getAttachmentPieceForAttachment(attachment)
    @attachmentEditor = new Trix.AttachmentEditorController attachmentPiece, element, @element
    @attachmentEditor.delegate = this

  uninstallAttachmentEditor: ->
    @attachmentEditor?.uninstall()

  reinstallAttachmentEditor: ->
    if @attachmentEditor
      attachment = @attachmentEditor.attachment
      @uninstallAttachmentEditor()
      @installAttachmentEditorForAttachment(attachment)

  editAttachmentCaption: ->
    @attachmentEditor?.editCaption()

  # Attachment controller delegate

  didUninstallAttachmentEditor: ->
    delete @attachmentEditor
    @render()

  attachmentEditorDidRequestUpdatingAttributesForAttachment: (attributes, attachment) ->
    @delegate?.compositionControllerWillUpdateAttachment?(attachment)
    @composition.document.updateAttributesForAttachment(attributes, attachment)

  attachmentEditorDidRequestRemovingAttributeForAttachment: (attribute, attachment) ->
    @delegate?.compositionControllerWillUpdateAttachment?(attachment)
    @composition.document.removeAttributeForAttachment(attribute, attachment)

  attachmentEditorDidRequestRemovalOfAttachment: (attachment) ->
    @delegate?.compositionControllerDidRequestRemovalOfAttachment?(attachment)

  attachmentEditorDidRequestDeselectingAttachment: (attachment) ->
    @delegate?.compositionControllerDidRequestDeselectingAttachment?(attachment)

  # Private

  findAttachmentForElement: (element) ->
    @composition.document.getAttachmentById(parseInt(element.dataset.trixId, 10))