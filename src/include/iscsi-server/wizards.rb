# encoding: utf-8

# |***************************************************************************
# |
# | Copyright (c) [2012] Novell, Inc.
# | All Rights Reserved.
# |
# | This program is free software; you can redistribute it and/or
# | modify it under the terms of version 2 of the GNU General Public License as
# | published by the Free Software Foundation.
# |
# | This program is distributed in the hope that it will be useful,
# | but WITHOUT ANY WARRANTY; without even the implied warranty of
# | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# | GNU General Public License for more details.
# |
# | You should have received a copy of the GNU General Public License
# | along with this program; if not, contact Novell, Inc.
# |
# | To contact Novell about this file by physical or electronic mail,
# | you may find current contact information at www.novell.com
# |
# |***************************************************************************
# File:	include/iscsi-server/wizards.ycp
# Package:	Configuration of iscsi-server
# Summary:	Wizards definitions
# Authors:	Michal Zugec <mzugec@suse.cz>
#
# $Id$
module Yast
  module IscsiServerWizardsInclude
    def initialize_iscsi_server_wizards(include_target)
      Yast.import "UI"

      textdomain "iscsi-server"

      Yast.import "Sequencer"
      Yast.import "Wizard"

      Yast.include include_target, "iscsi-server/complex.rb"
      Yast.include include_target, "iscsi-server/dialogs.rb"
    end

    # Main workflow of the iscsi-server configuration
    # @return sequence result
    def MainSequence
      # FIXME: adapt to your needs
      aliases = {
        "summary" => lambda { SummaryDialog() },
        "add"     => lambda { AddDialog() },
        "edit"    => lambda { EditDialog() },
        "auth"    => lambda { AuthDialog() },
        "expert"  => lambda { ExpertDialog() }
      }

      # FIXME: adapt to your needs
      sequence = {
        "ws_start" => "summary",
        "summary"  => {
          :abort => :abort,
          :next  => :next,
          :add   => "add",
          :edit  => "edit"
        },
        "add"      => {
          :abort  => :abort,
          :next   => "auth",
          :back   => :back,
          :expert => "expert"
        },
        "expert"   => { :abort => :abort, :next => "add", :back => :back },
        "edit"     => { :abort => :abort, :next => "auth", :back => :back },
        "auth"     => { :abort => :abort, :next => "summary", :back => :back }
      }

      ret = Sequencer.Run(aliases, sequence)

      deep_copy(ret)
    end

    # Whole configuration of iscsi-server
    # @return sequence result
    def IscsiServerSequence
      aliases = {
        "read"  => [lambda { ReadDialog() }, true],
        "main"  => lambda { MainSequence() },
        "write" => [lambda { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "read",
        "read"     => { :abort => :abort, :next => "main" },
        "main"     => { :abort => :abort, :next => "write" },
        "write"    => { :abort => :abort, :next => :next }
      }

      Wizard.OpenCancelOKDialog
      Wizard.SetDesktopTitleAndIcon("iscsi-server")

      ret = Sequencer.Run(aliases, sequence)

      UI.CloseDialog
      deep_copy(ret)
    end

    # Whole configuration of iscsi-server but without reading and writing.
    # For use with autoinstallation.
    # @return sequence result
    def IscsiServerAutoSequence
      # Initialization dialog caption
      caption = _("iSCSI Target Configuration")
      # Initialization dialog contents
      contents = Label(_("Initializing..."))

      Wizard.CreateDialog
      Wizard.SetContentsButtons(
        caption,
        contents,
        "",
        Label.BackButton,
        Label.NextButton
      )

      ret = MainSequence()

      UI.CloseDialog
      deep_copy(ret)
    end
  end
end
