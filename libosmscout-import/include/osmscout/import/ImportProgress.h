#ifndef OSMSCOUT_IMPORTPROGRESS_H
#define OSMSCOUT_IMPORTPROGRESS_H

/*
  This source is part of the libosmscout library
  Copyright (C) 2020  Lukas Karas

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
*/

#include <osmscout/import/ImportImportExport.h>
#include <osmscout/import/ImportModule.h>

#include <osmscout/util/Progress.h>
#include <osmscout/util/MemoryMonitor.h>

namespace osmscout {

class OSMSCOUT_IMPORT_API ImportProgress: public ConsoleProgress
{
public:
  ImportProgress() = default;
  virtual ~ImportProgress() = default;

  virtual void StartImport();
  virtual void FinishedImport();

  void DumpModuleDescription(const ImportModuleDescription& description);

  virtual void StartModule(size_t currentStep, const ImportModuleDescription& moduleDescription);
  virtual void FinishedModule();
};

class OSMSCOUT_IMPORT_API StatImportProgress: public ImportProgress
{
public:
  StatImportProgress() = default;
  virtual ~StatImportProgress() = default;

  void StartImport() override;
  void FinishedImport() override;

  void StartModule(size_t currentStep, const ImportModuleDescription& moduleDescription) override;
  virtual void FinishedModule();

private:
  StopClock timer;
  StopClock overAllTimer;
  MemoryMonitor monitor;
  double maxVMUsage=0.0;
  double maxResidentSet=0.0;
};

}

#endif //OSMSCOUT_IMPORTPROGRESS_H
